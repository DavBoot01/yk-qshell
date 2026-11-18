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
                + (Theme.bar.floating ? Theme.bar.floatingMargin * 2 : 0)

            // Window is taller than _reservedHeight when shadow needs extra room.
            implicitHeight: _reservedHeight
                + (Theme.bar.floating && Theme.bar.stripShadowEnabled
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
                x: Theme.bar.floating ? Theme.bar.floatingMargin : 0
                width: parent.width - (Theme.bar.floating ? Theme.bar.floatingMargin * 2 : 0)
                height: Theme.sizes.barHeight

                // y animates between _shownY (visible) and _hiddenY (off-screen above).
                readonly property real _shownY:  Theme.bar.floating
                    ? Theme.bar.floatingMargin : 0
                readonly property real _hiddenY: -(barStrip.height
                    + (Theme.bar.floating ? Theme.bar.floatingMargin : 0))

                y: barWindow._mustShow ? barStrip._shownY : barStrip._hiddenY

                Behavior on y {
                    NumberAnimation {
                        duration:    Theme.animation.duration
                        easing.type: Easing.OutCubic
                    }
                }

                color: Theme.bar.stripBackground

                topLeftRadius:     Theme.bar.stripRadiusTopLeft
                topRightRadius:    Theme.bar.stripRadiusTopRight
                bottomLeftRadius:  Theme.bar.stripRadiusBottomLeft
                bottomRightRadius: Theme.bar.stripRadiusBottomRight

                // Strip drop shadow via MultiEffect
                layer.enabled: Theme.bar.stripShadowEnabled
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

                // ── Left pill ─────────────────────────────────────────────────
                BarPill {
                    id: leftPill
                    anchors {
                        left:           parent.left
                        leftMargin:     Theme.bar.horizontalMargin
                        verticalCenter: parent.verticalCenter
                    }
                    screen:    barWindow.modelData
                    styleMode: root.leftStyle
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
                        rightMargin:    Theme.bar.horizontalMargin
                        verticalCenter: parent.verticalCenter
                    }
                    screen:    barWindow.modelData
                    styleMode: root.rightStyle
                    content:   root.rightContent
                }
            }
        }
    }
}
