pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

import qs
import qs.themes
import qs.services

// BarContainer — full-width bar with three inner pills.
//
// One PanelWindow per screen spans the full edge.
// Inside: a strip Rectangle (barStrip) containing three pill-shaped Rectangles
// (left / center / right).
//
// ── Shape ─────────────────────────────────────────────────────────────────────
// Theme.bar.shape "strip" paints barStrip itself; "tabs" (default) leaves it
// transparent and paints one BarTab behind each pill, bound to the pill's
// geometry so it follows the pill's width animation.
//
// ── Auto-hide ─────────────────────────────────────────────────────────────────
// Controlled by Theme.bar.autoHide.enabled (default: false = always visible).
// When enabled, barStrip slides off the screen edge when idle.
// The bar reveals when:
//   • the cursor enters the thin hover zone at the screen edge, or
//   • the Super key is held long enough (superShowDelay timer fires).
// The exclusive zone is set to 0 while hidden so windows can use that space.
//
// The input mask (_maskTarget) always exposes at least hoverRegionHeight pixels
// at the top of the window so hover events reach the window even when hidden.
//
// ── Centre panel (shape "tabs", Theme.centerDropdown.morph) ──────────────────
// The centre tab grows the centre panel out of itself, as a drawer. One
// progress `_dropT`, linear in time, drives eased stages
// (Theme.centerDropdown.*Stage): the pill's chips fade out while the tab widens
// along the bar — as far as the side tabs let it; the page tabs (`centerTabs`)
// fade in where the chips were; the panel drops from the tab at its own width,
// in the tab's outline (BarTab's drop); its content fades in last. Closing runs
// `_dropT` back to 0, so everything goes back in the reverse order. The window
// is tall enough for the panel at all times; the input mask follows what is
// open.
//
// ── Blur ──────────────────────────────────────────────────────────────────────
// Compositor-side blur. Enable in Hyprland:
//   layerrule = blur, ^(myshell:bar)$
//   layerrule = ignorealpha 0.05, ^(myshell:bar)$
Scope {
    id: root

    // "top" | "bottom"
    property string position: "top"

    // Tabs hang from the edge, so they never float.
    readonly property bool _tabs:     Theme.bar.shape === "tabs"
    readonly property bool _floating: Theme.bar.floating && !root._tabs

    // Side pills' distance from the screen's sides: room for a side tab's
    // margin, flare and padding when the tabs stand off the corners.
    readonly property real _sideMargin: root._tabs && !Theme.bar.tabFlushEdges
        ? Theme.bar.tabEdgeMargin + Theme.bar.tabFlare + Theme.bar.tabPadding
        : Theme.bar.horizontalMargin

    // Content slots — bind in modules/bar/Bar.qml
    property Component leftContent:   null
    property Component centerContent: null
    property Component rightContent:  null

    // The centre panel's pages, shown in the centre tab while it is open:
    // [{ id, icon, label }]; `id` is the PanelManager content id.
    property var centerTabs: []

    // Per-pill style overrides — forwarded to each BarPill instance.
    // Defaults to Theme.bar.pill.defaultStyle; override per-pill in Bar.qml.
    property string leftStyle:   Theme.bar.pill.defaultStyle
    property string centerStyle: Theme.bar.pill.defaultStyle
    property string rightStyle:  Theme.bar.pill.defaultStyle

    // ── Bar window (one per screen) ───────────────────────────────────────────
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: barWindow
            required property ShellScreen modelData
            screen: modelData

            WlrLayershell.namespace:     "myshell:bar"
            WlrLayershell.layer:         WlrLayer.Top
            WlrLayershell.keyboardFocus: barWindow._dropOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            color: "transparent"

            anchors {
                top:    root.position === "top"
                bottom: root.position === "bottom"
                left:   true
                right:  true
            }

            // ── Visibility state ──────────────────────────────────────────────

            // True after _superTimer fires — cleared when Super is released.
            property bool _superShow: false

            // mustShow: true when the strip should be visible.
            //   • Always true when auto-hide is disabled.
            //   • Forced false when barOpen=false or screenLocked=true.
            //   • Otherwise: hover or super-reveal.
            readonly property bool _mustShow: GlobalStates.barOpen
                && !GlobalStates.screenLocked
                && (!Theme.bar.autoHide.enabled
                    || hoverRegion.containsMouse
                    || barWindow._superShow)

            // ── Sizing ────────────────────────────────────────────────────────

            // Reserved screen edge height (strut) when the bar is shown.
            readonly property real _reservedHeight: Theme.sizes.barHeight
                + (root._floating ? Theme.bar.floatingMargin * 2 : 0)

            // Window is taller than _reservedHeight when shadow needs extra room,
            // and by the centre panel's height when the tab grows it.
            implicitHeight: _reservedHeight
                + (root._floating && Theme.bar.stripShadowEnabled
                   ? Theme.bar.stripShadowRadius
                     + Math.max(Theme.bar.stripShadowOffsetY, 0)
                   : 0)
                + (barWindow._morph ? barWindow._dropFullHeight + Theme.surface.rimWidth * 2 : 0)

            // ── Centre panel grown from the tab ───────────────────────────────
            readonly property bool _morph: root._tabs && Theme.centerDropdown.morph
                && root.position === "top"

            readonly property bool _dropOpen: barWindow._morph
                && PanelManager.activePanelId === "center-dropdown"
                && (PanelManager.activeScreen ?? barWindow.modelData) === barWindow.modelData

            readonly property real _dropFullWidth: Math.max(
                Math.min(barWindow.modelData.width * Theme.centerDropdown.widthFraction,
                         Theme.centerDropdown.maxWidth),
                Theme.centerDropdown.minWidth, barWindow._restWidth)

            // The centre tab's body: at rest around its pill, open as wide as
            // the panel or as the side tabs allow.
            readonly property real _cx: centerPill.x + centerPill.width / 2
            readonly property real _restWidth: centerPill.width + Theme.bar.tabPadding * 2
            readonly property real _roomWidth: 2 * (Math.min(
                    barWindow._cx - (leftPill.x + leftPill.width),
                    rightPill.x - barWindow._cx)
                - Theme.bar.tabPadding - Theme.bar.tabFlare * 2 - Theme.centerDropdown.tabGap)
            readonly property real _openWidth: Math.max(barWindow._restWidth,
                Math.min(barWindow._dropFullWidth, barWindow._roomWidth))
            readonly property real _dropFullHeight: Math.min(
                Math.round(barWindow.modelData.height / 4), Theme.sizes.centerDropdownMaxHeight)

            // Linear in time; the channels below ease it.
            property real _dropT: 0

            function _ease(x: real): real {
                const c = Math.max(0, Math.min(1, x))
                return 1 - Math.pow(1 - c, 4)
            }
            function _stage(range: var): real {
                return barWindow._ease((barWindow._dropT - range[0]) / Math.max(0.001, range[1] - range[0]))
            }
            readonly property real _sChips:   barWindow._stage(Theme.centerDropdown.chipsStage)
            readonly property real _sWiden:   barWindow._stage(Theme.centerDropdown.widenStage)
            readonly property real _sHeader:  barWindow._stage(Theme.centerDropdown.headerStage)
            readonly property real _sDrop:    barWindow._stage(Theme.centerDropdown.dropStage)
            readonly property real _sContent: barWindow._stage(Theme.centerDropdown.contentStage)

            readonly property real _bodyWidth: barWindow._restWidth
                + (barWindow._openWidth - barWindow._restWidth) * barWindow._sWiden
            readonly property real _dropWidth: barWindow._bodyWidth
                + (barWindow._dropFullWidth - barWindow._bodyWidth) * barWindow._sDrop
            readonly property real _dropHeight: barWindow._dropFullHeight * barWindow._sDrop

            // The content stays while the panel closes, even when another panel
            // has already taken the manager.
            property Component _dropContent: null
            // The page shown last, so the page tabs keep it while closing.
            property string _lastPage: ""
            Connections {
                target: PanelManager
                function onActiveContentIdChanged(): void {
                    if (barWindow._dropOpen)
                        barWindow._lastPage = PanelManager.activeContentId
                }
            }
            Binding {
                target:      barWindow
                property:    "_dropContent"
                value:       PanelManager.activeContent
                when:        barWindow._dropOpen
                restoreMode: Binding.RestoreNone
            }

            on_DropOpenChanged: {
                // A reversal mid-way takes the share of the time that is left.
                if (barWindow._dropOpen) {
                    barWindow._lastPage = PanelManager.activeContentId
                    dropClose.stop()
                    dropOpenAnim.duration = Theme.centerDropdown.openDuration * (1 - barWindow._dropT)
                    dropOpenAnim.restart()
                } else if (barWindow._dropT > 0) {
                    dropOpenAnim.stop()
                    dropClose.duration = Theme.centerDropdown.closeDuration * barWindow._dropT
                    dropClose.restart()
                }
            }

            NumberAnimation {
                id: dropOpenAnim
                target: barWindow; property: "_dropT"; to: 1
            }
            NumberAnimation {
                id: dropClose
                target: barWindow; property: "_dropT"; to: 0
                onFinished: barWindow._dropContent = null
            }

            Shortcut {
                sequence:    "Escape"
                enabled:     barWindow._dropOpen
                onActivated: PanelManager.close()
            }

            // Exclusive zone: reserve screen space only while strip is visible.
            exclusiveZone: barWindow._mustShow ? barWindow._reservedHeight : 0

            // ── Input mask ────────────────────────────────────────────────────
            // _maskTarget dynamically covers the visible strip area.
            // When hidden it shrinks to a thin hover zone so cursor events still
            // reach the window and can trigger the reveal.
            mask: Region {
                item: _maskTarget
                Region { item: _dropMask }
            }

            // While the centre panel is open, the band below the bar takes the
            // clicks, so one beside the panel closes it.
            Item {
                id: _dropMask
                y:      barStrip.y + barStrip.height
                width:  parent.width
                height: barWindow._dropT > 0 ? barWindow._dropFullHeight + Theme.surface.rimWidth * 2 : 0
            }

            MouseArea {
                anchors.fill: _dropMask
                enabled:      barWindow._dropT > 0
                onClicked: mouse => {
                    const p = mapToItem(dropArea, mouse.x, mouse.y)
                    if (!dropArea.contains(Qt.point(p.x, p.y)))
                        PanelManager.close()
                }
            }

            Item {
                id: _maskTarget
                y: 0
                width: parent.width
                // Bottom edge tracks the bottom of barStrip in window coordinates.
                // Math.max ensures the hover zone is never smaller than hoverRegionHeight.
                height: Math.max(
                    barStrip.y + barStrip.height,
                    Theme.bar.autoHide.hoverRegionHeight
                )
            }

            // ── Hover detection ───────────────────────────────────────────────
            // Fills the window but is only reached within the mask area.
            // containsMouse fires when cursor is in the thin reveal zone (hidden)
            // or anywhere over the strip (shown).
            MouseArea {
                id: hoverRegion
                anchors.fill: parent
                hoverEnabled: true
                propagateComposedEvents: true
                acceptedButtons: Qt.NoButton
            }

            // ── Super-key reveal ──────────────────────────────────────────────
            // A single-shot timer delays the reveal so quick Super shortcuts
            // (launcher, WM binds) don't accidentally flash the bar.
            Timer {
                id: _superTimer
                interval: Theme.bar.autoHide.superShowDelay
                repeat:   false
                onTriggered: barWindow._superShow = true
            }

            Connections {
                target:  GlobalStates
                enabled: Theme.bar.autoHide.enabled && Theme.bar.autoHide.showOnSuper

                function onSuperDownChanged(): void {
                    if (GlobalStates.superDown) {
                        _superTimer.restart()
                    } else {
                        _superTimer.stop()
                        barWindow._superShow = false
                    }
                }
            }

            // ── Strip ─────────────────────────────────────────────────────────
            Rectangle {
                id: barStrip

                // Floating: strip is inset from window edges; otherwise flush.
                x: root._floating ? Theme.bar.floatingMargin : 0
                width: parent.width - (root._floating ? Theme.bar.floatingMargin * 2 : 0)
                height: Theme.sizes.barHeight

                // y animates between _shownY (visible) and _hiddenY (off-screen above).
                readonly property real _shownY:  root._floating
                    ? Theme.bar.floatingMargin : 0
                readonly property real _hiddenY: -(barStrip.height
                    + (root._floating ? Theme.bar.floatingMargin : 0))

                y: barWindow._mustShow ? barStrip._shownY : barStrip._hiddenY

                Behavior on y {
                    NumberAnimation {
                        duration:    Theme.animation.duration
                        easing.type: Easing.OutCubic
                    }
                }

                color: root._tabs ? "transparent" : Theme.bar.stripBackground

                topLeftRadius:     Theme.bar.stripRadiusTopLeft
                topRightRadius:    Theme.bar.stripRadiusTopRight
                bottomLeftRadius:  Theme.bar.stripRadiusBottomLeft
                bottomRightRadius: Theme.bar.stripRadiusBottomRight

                // Strip drop shadow via MultiEffect
                layer.enabled: Theme.bar.stripShadowEnabled && !root._tabs
                layer.effect: MultiEffect {
                    shadowEnabled:          Theme.bar.stripShadowEnabled
                    shadowColor:            Theme.bar.stripShadowColor
                    shadowBlur:             Math.min(Theme.bar.stripShadowRadius / 64.0, 1.0)
                    shadowHorizontalOffset: Theme.bar.stripShadowOffsetX
                    shadowVerticalOffset:   Theme.bar.stripShadowOffsetY
                }

                // ── Strip-level dismiss ───────────────────────────────────────
                // Closes any open overlay panel when clicking on empty bar space.
                // z: -1 keeps it below the pills, so chip clicks are handled
                // exclusively by the chips themselves.
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: {
                        if (PanelManager.activePanelId !== "")
                            PanelManager.close()
                    }
                }

                // ── Tabs (shape "tabs") ───────────────────────────────────────
                // Behind the pills; each spans its pill plus padding plus flares.
                BarTab {
                    readonly property bool _flush: Theme.bar.tabFlushEdges
                    visible:    root._tabs
                    x:          _flush ? 0 : leftPill.x - Theme.bar.tabPadding - flare
                    width:      leftPill.x + leftPill.width + Theme.bar.tabPadding + flare - x
                    height:     parent.height
                    flareLeft:  !_flush
                    fillColor:  Theme.bar.tabBackground
                    radius:     Theme.bar.tabRadius
                    flare:      Theme.bar.tabFlare
                    sheen:      Theme.surface.sheen
                    rimColor:   Theme.surface.rimColor
                    rimWidth:   Theme.surface.rimWidth
                    mirrored:   root.position === "bottom"
                }
                BarTab {
                    visible:   root._tabs
                    x:         barWindow._cx - barWindow._bodyWidth / 2 - flare
                    width:     barWindow._bodyWidth + flare * 2
                    bodyHeight: parent.height
                    height:    parent.height + dropHeight

                    dropHeight:    barWindow._dropHeight
                    dropWidth:     barWindow._dropWidth
                    dropRadius:    radius + (Theme.centerDropdown.bottomLeftRadius - radius) * barWindow._sDrop
                    dropTopRadius: radius
                    dropFillet:    flare
                    fillColor: Theme.bar.tabBackground
                    radius:    Theme.bar.tabRadius
                    flare:     Theme.bar.tabFlare
                    sheen:     Theme.surface.sheen
                    rimColor:  Theme.surface.rimColor
                    rimWidth:  Theme.surface.rimWidth
                    mirrored:  root.position === "bottom"
                }
                BarTab {
                    readonly property bool _flush: Theme.bar.tabFlushEdges
                    visible:    root._tabs
                    x:          rightPill.x - Theme.bar.tabPadding - flare
                    width:      (_flush ? parent.width : rightPill.x + rightPill.width + Theme.bar.tabPadding + flare) - x
                    height:     parent.height
                    flareRight: !_flush
                    fillColor:  Theme.bar.tabBackground
                    radius:     Theme.bar.tabRadius
                    flare:      Theme.bar.tabFlare
                    sheen:      Theme.surface.sheen
                    rimColor:   Theme.surface.rimColor
                    rimWidth:   Theme.surface.rimWidth
                    mirrored:   root.position === "bottom"
                }

                // ── Centre panel's content ────────────────────────────────────
                // The rectangle the drop covers now; the content keeps the
                // panel's full size, is clipped by it, and fades in last.
                Item {
                    id: dropArea
                    visible: barWindow._dropT > 0
                    clip:    true
                    width:   barWindow._dropWidth
                    height:  barWindow._dropHeight
                    x:       barWindow._cx - width / 2
                    y:       parent.height
                    z:       1

                    Loader {
                        width:   barWindow._dropFullWidth - 32
                        height:  barWindow._dropFullHeight - 32
                        x:       (parent.width - width) / 2
                        y:       16 + (1 - barWindow._sContent) * Theme.centerDropdown.contentRise
                        opacity: barWindow._sContent
                        active:  barWindow._dropContent !== null
                        sourceComponent: barWindow._dropContent
                    }
                }

                // ── Left pill ─────────────────────────────────────────────────
                BarPill {
                    id: leftPill
                    anchors {
                        left:           parent.left
                        leftMargin:     root._sideMargin
                        verticalCenter: parent.verticalCenter
                    }
                    screen:    barWindow.modelData
                    styleMode: root.leftStyle
                    contentAlign: "left"
                    content:   root.leftContent
                }

                // ── Center pill ───────────────────────────────────────────────
                BarPill {
                    id: centerPill
                    anchors.centerIn: parent
                    screen:    barWindow.modelData
                    styleMode: root.centerStyle
                    content:   root.centerContent
                    // Gives way to the page tabs while the centre panel is open.
                    opacity:   1 - barWindow._sChips
                    enabled:   barWindow._sChips < 0.5
                    visible:   opacity > 0
                }

                // ── Page tabs (centre panel open) ─────────────────────────────
                // Where the chips were: the active page with its icon and
                // label, the others by their icon; a click turns the page, and
                // the active one closes the panel.
                Row {
                    id: pageTabs
                    anchors.verticalCenter: parent.verticalCenter
                    x:       Math.round(barWindow._cx - width / 2)
                    z:       2
                    spacing: 4
                    opacity: barWindow._sHeader
                    visible: opacity > 0 && root.centerTabs.length > 0
                    enabled: barWindow._dropOpen

                    Repeater {
                        model: root.centerTabs
                        delegate: Rectangle {
                            id: pageTab
                            required property var modelData
                            readonly property bool _active: PanelManager.activeContentId === modelData.id
                                || (!barWindow._dropOpen && barWindow._lastPage === modelData.id)

                            height: Theme.sizes.barHeight - Theme.bar.pill.verticalMargin * 2
                            width:  tabRow.implicitWidth + 20
                            radius: height / 2
                            color:  pageTab._active ? Theme.widget.activeBackground
                                  : tabMouse.containsMouse ? Theme.widget.hoverBackground : "transparent"

                            Behavior on width { NumberAnimation { duration: Theme.animation.duration; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation  { duration: Theme.animation.duration } }

                            Row {
                                id: tabRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text:           pageTab.modelData.icon
                                    color:          pageTab._active ? Theme.colors.primary : Theme.widget.textColorDim
                                    font.family:    Theme.widget.fontFamily
                                    font.pixelSize: Theme.widget.fontSize
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible:        pageTab._active
                                    text:           Translation.tr(pageTab.modelData.label)
                                    color:          Theme.widget.textColor
                                    font.family:    Theme.widget.fontFamily
                                    font.pixelSize: Theme.widget.fontSize
                                    font.bold:      true
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onClicked: PanelManager.toggle("center-dropdown", pageTab.modelData.id,
                                                               PanelManager.activeContent, barWindow.modelData)
                            }
                        }
                    }
                }

                // ── Right pill ────────────────────────────────────────────────
                BarPill {
                    id: rightPill
                    anchors {
                        right:          parent.right
                        rightMargin:    root._sideMargin
                        verticalCenter: parent.verticalCenter
                    }
                    screen:    barWindow.modelData
                    styleMode: root.rightStyle
                    contentAlign: "right"
                    content:   root.rightContent
                }
            }
        }
    }
}
