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
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

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

            // Window is taller than _reservedHeight when shadow needs extra room.
            implicitHeight: _reservedHeight
                + (root._floating && Theme.bar.stripShadowEnabled
                   ? Theme.bar.stripShadowRadius
                     + Math.max(Theme.bar.stripShadowOffsetY, 0)
                   : 0)

            // Exclusive zone: reserve screen space only while strip is visible.
            exclusiveZone: barWindow._mustShow ? barWindow._reservedHeight : 0

            // ── Input mask ────────────────────────────────────────────────────
            // _maskTarget dynamically covers the visible strip area.
            // When hidden it shrinks to a thin hover zone so cursor events still
            // reach the window and can trigger the reveal.
            mask: Region { item: _maskTarget }

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
                    x:         centerPill.x - Theme.bar.tabPadding - flare
                    width:     centerPill.width + (Theme.bar.tabPadding + flare) * 2
                    height:    parent.height
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
