pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

import qs.themes
import qs.services

// OverlayPanel — shared window infrastructure for every PanelManager-driven panel.
//
// One window that is hidden until PanelManager.activePanelId === panelId, then
// slides a panel Rectangle in from `edge` and slides it out again on close.
// Content is PanelManager.activeContent, copied locally so it survives the close
// animation even when another panel has already taken over the manager.
//
// ── Edges ─────────────────────────────────────────────────────────────────────
//   "top"   — window spans the top edge; panel is `panelWidth × panelHeight`,
//             centered, resting `topInset` below the screen edge.
//   "left" / "right" — full-screen window (for the dim layer); panel is
//             `panelWidth` wide and full height.
//
// ── Screen ────────────────────────────────────────────────────────────────────
//   Always PanelManager.activeScreen, so the panel appears only where the
//   triggering chip was clicked.
//
// ── Dismiss ───────────────────────────────────────────────────────────────────
//   Click outside the panel → PanelManager.close(); Esc closes too (once the
//   panel has keyboard focus, i.e. after a click inside it).
//   Input mask while visible: "top" panels exclude the bar area, so bar chips
//   stay clickable (switching/toggling pages works); left/right panels mask the
//   whole window because their dim layer covers the bar.
//
// Concrete panels only set geometry + style; see CenterDropdown / SidePanelLeft /
// SidePanelRight.
PanelWindow {
    id: win

    required property string panelId

    // "top" | "left" | "right"
    property string edge: "top"

    property real panelWidth:  0
    property real panelHeight: 0     // ignored for left/right (full height)
    property real topInset:    0     // edge === "top": gap between screen edge and panel

    // ── Style ─────────────────────────────────────────────────────────────────
    property color panelColor:        "transparent"
    property real  topLeftRadius:     0
    property real  topRightRadius:    0
    property real  bottomLeftRadius:  0
    property real  bottomRightRadius: 0
    property real  contentMargin:     0

    property bool  shadowEnabled:  false
    property real  shadowRadius:   12
    property color shadowColor:    Qt.rgba(0, 0, 0, 0.5)
    property real  shadowOffsetX:  0
    property real  shadowOffsetY:  4

    // Dim layer behind the panel (0 = none).
    property real  dimOpacity: 0
    property color dimColor:   "#000000"

    // ── Window ────────────────────────────────────────────────────────────────
    screen: PanelManager.activeScreen

    WlrLayershell.namespace:     "myshell:" + win.panelId
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color:         "transparent"
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    visible:       false

    readonly property bool _isTop: win.edge === "top"

    anchors {
        top:    true
        left:   true
        right:  true
        bottom: !win._isTop
    }

    readonly property real _shadowOverflow: win.shadowEnabled
        ? win.shadowRadius + Math.max(win.shadowOffsetY, 0) : 0

    // Only meaningful for "top"; left/right are stretched by their anchors.
    implicitHeight: win.topInset + win.panelHeight + win._shadowOverflow

    // ── Slide geometry ────────────────────────────────────────────────────────
    readonly property string _axis: win._isTop ? "y" : "x"
    readonly property real _shownPos: win.edge === "top"  ? win.topInset
                                    : win.edge === "left" ? 0
                                    : win.width - win.panelWidth
    readonly property real _hiddenPos: win.edge === "top"  ? -win.panelHeight
                                     : win.edge === "left" ? -win.panelWidth
                                     : win.width

    // 0 = fully hidden, 1 = fully shown (drives the dim layer).
    readonly property real _progress: {
        const span = win._shownPos - win._hiddenPos
        if (span === 0) return 0
        const cur = win._isTop ? panel.y : panel.x
        return Math.max(0, Math.min(1, (cur - win._hiddenPos) / span))
    }

    // ── Content ───────────────────────────────────────────────────────────────
    property Component _content: null

    Binding {
        target:      win
        property:    "_content"
        value:       PanelManager.activeContent
        when:        PanelManager.activePanelId === win.panelId
        restoreMode: Binding.RestoreNone
    }

    // ── Input ─────────────────────────────────────────────────────────────────
    Item {
        id: _inputArea
        y:      win._isTop ? win.topInset : 0
        width:  parent.width
        height: parent.height - y
    }
    mask: Region { item: _inputArea }

    Shortcut {
        sequence:  "Escape"
        enabled:   win.visible
        onActivated: PanelManager.close()
    }

    // z: -1 keeps this below the panel so panel clicks never reach it.
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: mouse => {
            const local = mapToItem(panel, mouse.x, mouse.y)
            if (!panel.contains(Qt.point(local.x, local.y)))
                PanelManager.close()
        }
    }

    // ── State transitions ─────────────────────────────────────────────────────
    Connections {
        target: PanelManager
        function onActivePanelIdChanged(): void {
            if (PanelManager.activePanelId === win.panelId) {
                closeAnim.stop()
                if (!win.visible) win._place(win._hiddenPos)
                win.visible = true
                openAnim.restart()
            } else if (win.visible) {
                openAnim.stop()
                closeAnim.restart()
            }
        }
    }

    function _place(pos: real): void {
        if (win._isTop) panel.y = pos
        else            panel.x = pos
    }

    NumberAnimation {
        id: openAnim
        target:      panel
        property:    win._axis
        to:          win._shownPos
        duration:    Theme.animation.durationLong
        easing.type: Easing.OutExpo
    }

    NumberAnimation {
        id: closeAnim
        target:      panel
        property:    win._axis
        to:          win._hiddenPos
        duration:    Theme.animation.durationLong
        easing.type: Easing.InCubic
        onFinished: {
            win.visible = false
            win._content = null
        }
    }

    // ── Dim ───────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        visible: win.dimOpacity > 0
        color:   win.dimColor
        opacity: win.visible ? win._progress * win.dimOpacity : 0
    }

    // ── Panel ─────────────────────────────────────────────────────────────────
    Rectangle {
        id: panel

        width:  win.panelWidth
        height: win._isTop ? win.panelHeight : win.height
        x:      win._isTop ? Math.round((win.width - width) / 2) : win._hiddenPos
        y:      win._isTop ? -win.panelHeight : 0

        color: win.panelColor

        topLeftRadius:     win.topLeftRadius
        topRightRadius:    win.topRightRadius
        bottomLeftRadius:  win.bottomLeftRadius
        bottomRightRadius: win.bottomRightRadius

        layer.enabled: win.shadowEnabled
        layer.effect: MultiEffect {
            shadowEnabled:          win.shadowEnabled
            shadowColor:            win.shadowColor
            shadowBlur:             Math.min(win.shadowRadius / 64.0, 1.0)
            shadowHorizontalOffset: win.shadowOffsetX
            shadowVerticalOffset:   win.shadowOffsetY
        }

        Loader {
            anchors.fill:    parent
            anchors.margins: win.contentMargin
            clip:            true
            sourceComponent: win._content
        }
    }
}
