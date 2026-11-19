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
// ── Panels grown from the tabs (shape "tabs", top bar) ─────────────────────
// The centre tab grows the centre panel out of itself, as a drawer (TabDrawer,
// Theme.centerDropdown.morph): the pill's chips rise out of the tab while it
// widens along the bar — as far as the side tabs let it; the panel's page tabs
// (`centerTabs`, PageTabs) rise into it; the panel drops from the tab in its
// outline (BarTab's drop); its content fades in last.
//
// The right panel grows out of the right tab's outer bottom corner, as if the
// bar burst open there: in one outline with the tab (SideDock), its width and
// height grow from the corner, flush with the tab's right side and standing off
// the screen's; the tab's flares give way to convex corners, so the open panel
// is one card rounded alike all round; its content comes in last, drifting out
// of the corner (Theme.sidePanel.morph). It dims the screen behind it.
//
// Closing runs either backwards. The window spans the screen while either can
// open; the input mask follows what shows.
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
            WlrLayershell.keyboardFocus: centerDrawer.open || rightDrawer.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

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

            // Window: the strip, and room for its shadow; with a panel grown
            // from a tab, the whole screen, so the panel fits — the input mask
            // keeps to what shows.
            readonly property bool _morphTop: root._tabs && root.position === "top"
            implicitHeight: barWindow._morphTop && (Theme.centerDropdown.morph || Theme.sidePanel.morph)
                ? barWindow.modelData.height
                : _reservedHeight
                  + (root._floating && Theme.bar.stripShadowEnabled
                     ? Theme.bar.stripShadowRadius
                       + Math.max(Theme.bar.stripShadowOffsetY, 0)
                     : 0)

            // Exclusive zone: reserve screen space only while strip is visible.
            exclusiveZone: barWindow._mustShow ? barWindow._reservedHeight : 0

            // ── Centre panel, grown from the centre tab ───────────────────────
            TabDrawer {
                id: centerDrawer
                panelId: "center-dropdown"
                screen:  barWindow.modelData
                style:   Theme.centerDropdown
                enabled: barWindow._morphTop && Theme.centerDropdown.morph
            }

            readonly property real _cx: centerPill.x + centerPill.width / 2
            // The centre tab's body: at rest around its pill, open as wide as
            // the panel or as the side tabs allow.
            readonly property real _cRest: centerPill.width + Theme.bar.tabPadding * 2
            readonly property real _cFullWidth: Math.max(
                Math.min(barWindow.modelData.width * Theme.centerDropdown.widthFraction,
                         Theme.centerDropdown.maxWidth),
                Theme.centerDropdown.minWidth, barWindow._cRest)
            readonly property real _cFullHeight: Math.min(
                Math.round(barWindow.modelData.height / 4), Theme.sizes.centerDropdownMaxHeight)
            readonly property real _cRoom: 2 * (Math.min(
                    barWindow._cx - (leftPill.x + leftPill.width),
                    rightPill.x - barWindow._cx)
                - Theme.bar.tabPadding - Theme.bar.tabFlare * 2 - Theme.centerDropdown.tabGap)
            readonly property real _cOpen: Math.max(barWindow._cRest,
                Math.min(barWindow._cFullWidth, barWindow._cRoom))
            readonly property real _cBody: barWindow._cRest
                + (barWindow._cOpen - barWindow._cRest) * centerDrawer.widen
            readonly property real _cDropWidth: barWindow._cBody
                + (barWindow._cFullWidth - barWindow._cBody) * centerDrawer.drop
            readonly property real _cDropHeight: barWindow._cFullHeight * centerDrawer.drop

            // ── Right panel, slid in and locked into the right tab ────────────
            TabDrawer {
                id: rightDrawer
                panelId: "side-right"
                screen:  barWindow.modelData
                style:   Theme.sidePanel
                enabled: barWindow._morphTop && Theme.sidePanel.morph
            }
            readonly property real _rGrow:    rightDrawer.stage(Theme.sidePanel.growStage)
            readonly property real _rGrowW:   rightDrawer.stage(Theme.sidePanel.widthStage)
            readonly property real _rCorners: rightDrawer.stage(Theme.sidePanel.cornersStage)
            readonly property real _rContent: rightDrawer.stage(Theme.sidePanel.contentStage)

            // The right tab at rest, in the strip's coordinates.
            readonly property real _rLeft:  rightPill.x - Theme.bar.tabPadding
            readonly property real _rRight: Theme.bar.tabFlushEdges
                ? barStrip.width : rightPill.x + rightPill.width + Theme.bar.tabPadding
            // The panel: flush with the tab's right side, standing off the
            // screen's side as the tab does and off its bottom by as much, at
            // least as wide as the tab.
            readonly property real _rGap: barStrip.width - barWindow._rRight
            readonly property real _rWidth: Math.max(Theme.sizes.sidebarWidth,
                barWindow._rRight - barWindow._rLeft)
            // Its height fits the page it shows (`preferredHeight`), between
            // a floor and a ceiling; a change of page animates to the new one.
            readonly property real _rMaxHeight: Math.min(
                barWindow.modelData.height - barStrip.y - barStrip.height - barWindow._rGap,
                Math.round(barWindow.modelData.height * Theme.sidePanel.heightFraction))
            readonly property real _rFit: rightContent.item && rightContent.item.preferredHeight > 0
                ? rightContent.item.preferredHeight + Theme.sidePanel.padding * 2 : 0
            readonly property real _rTargetHeight: Math.min(barWindow._rMaxHeight,
                Math.max(Theme.sidePanel.minHeight, barWindow._rFit))
            property real _rHeight: barWindow._rTargetHeight
            Behavior on _rHeight {
                enabled: rightDrawer.open && rightDrawer.t >= 1
                NumberAnimation { duration: Theme.animation.durationLong; easing.type: Easing.OutCubic }
            }
            // Growing out of the tab's outer bottom corner: from the corner's
            // own size to the panel's.
            readonly property real _rNowWidth: Theme.bar.tabRadius
                + (barWindow._rWidth - Theme.bar.tabRadius) * barWindow._rGrowW
            readonly property real _rNowHeight: barWindow._rHeight * barWindow._rGrow

            Shortcut {
                sequence:    "Escape"
                enabled:     centerDrawer.open || rightDrawer.open
                onActivated: PanelManager.close()
            }

            // ── Input mask ────────────────────────────────────────────────────
            // _maskTarget dynamically covers the visible strip area.
            // When hidden it shrinks to a thin hover zone so cursor events still
            // reach the window and can trigger the reveal. While a panel grown
            // from a tab shows, the screen below the bar takes the clicks too,
            // so one outside the panel closes it.
            mask: Region {
                item: _maskTarget
                Region { item: _panelMask }
            }

            Item {
                id: _panelMask
                y:      barStrip.y + barStrip.height
                width:  parent.width
                height: centerDrawer.shown || rightDrawer.shown ? parent.height - y : 0
            }

            // The right panel dims the screen behind it, the bar included.
            Rectangle {
                anchors.fill: parent
                visible: rightDrawer.shown && Theme.sidePanel.dimOpacity > 0
                color:   Theme.sidePanel.dimColor
                opacity: barWindow._rGrow * Theme.sidePanel.dimOpacity
            }

            MouseArea {
                anchors.fill: _panelMask
                enabled:      centerDrawer.shown || rightDrawer.shown
                onClicked: mouse => {
                    for (const area of [centerArea, rightArea]) {
                        const p = mapToItem(area, mouse.x, mouse.y)
                        if (area.visible && area.contains(Qt.point(p.x, p.y)))
                            return
                    }
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
                    visible:    root._tabs
                    x:          barWindow._cx - barWindow._cBody / 2 - flare
                    width:      barWindow._cBody + flare * 2
                    bodyHeight: parent.height
                    height:     parent.height + dropHeight

                    dropHeight:    barWindow._cDropHeight
                    dropWidth:     barWindow._cDropWidth
                    dropRadius:    radius + (Theme.centerDropdown.bottomLeftRadius - radius) * centerDrawer.drop
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
                    visible:    root._tabs && !rightDrawer.shown
                    x:          barWindow._rLeft - flare
                    width:      (_flush ? parent.width : barWindow._rRight + flare) - x
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

                // Open: tab and panel in one outline, the panel growing out
                // of the tab's outer bottom corner.
                SideDock {
                    // The flares give way to convex corners like the panel's:
                    // flares out over the first half, corners in over the second.
                    readonly property real _flaresOut: Math.min(1, barWindow._rCorners * 2)
                    readonly property real _cornersIn: Math.max(0, barWindow._rCorners * 2 - 1)

                    visible: root._tabs && rightDrawer.shown
                    width:   parent.width
                    height:  parent.height + barWindow._rNowHeight

                    bodyHeight:  parent.height
                    bodyLeft:    barWindow._rLeft
                    bodyRight:   barWindow._rRight
                    radius:      Theme.bar.tabRadius
                    leftFlare:   Theme.bar.tabFlare * (1 - _flaresOut)
                    rightFlare:  (Theme.bar.tabFlushEdges ? 0 : Theme.bar.tabFlare) * (1 - _flaresOut)
                    topCorner:   Theme.sidePanel.cornerRadius * _cornersIn
                    panelWidth:  barWindow._rNowWidth
                    panelHeight: barWindow._rNowHeight
                    cornerRadius: Theme.bar.tabRadius
                                  + (Theme.sidePanel.cornerRadius - Theme.bar.tabRadius) * barWindow._rGrow
                    fillet:      Theme.bar.tabFlare

                    fillColor: Theme.bar.tabBackground
                    sheen:     Theme.surface.sheen
                    rimColor:  Theme.surface.rimColor
                    rimWidth:  Theme.surface.rimWidth
                }

                // ── Panels' content ───────────────────────────────────────────
                // The rectangle a drop covers now; the content keeps its
                // panel's full size, is clipped by it, and fades in last.
                Item {
                    id: centerArea
                    visible: centerDrawer.shown
                    clip:    true
                    width:   barWindow._cDropWidth
                    height:  barWindow._cDropHeight
                    x:       barWindow._cx - width / 2
                    y:       parent.height
                    z:       1

                    Loader {
                        width:   barWindow._cFullWidth - 32
                        height:  barWindow._cFullHeight - 32
                        x:       (parent.width - width) / 2
                        y:       16 + (1 - centerDrawer.content) * Theme.centerDropdown.contentRise
                        opacity: centerDrawer.content
                        active:  centerDrawer.panelContent !== null
                        sourceComponent: centerDrawer.panelContent
                    }
                }

                // The right panel's content keeps the panel's full size,
                // anchored to the corner it grows from, is clipped by what has
                // grown, and comes in last, drifting out of that corner.
                Item {
                    id: rightArea
                    visible: rightDrawer.shown
                    clip:    true
                    x:       barWindow._rRight - width
                    y:       parent.height
                    width:   barWindow._rNowWidth
                    height:  barWindow._rNowHeight
                    z:       1

                    Loader {
                        id:      rightContent
                        width:   barWindow._rWidth - Theme.sidePanel.padding * 2
                        height:  barWindow._rHeight - Theme.sidePanel.padding * 2
                        x:       parent.width - width - Theme.sidePanel.padding
                                 + (1 - barWindow._rContent) * Theme.sidePanel.contentDrift
                        y:       Theme.sidePanel.padding
                                 - (1 - barWindow._rContent) * Theme.sidePanel.contentDrift
                        opacity: barWindow._rContent
                        active:  rightDrawer.panelContent !== null
                        sourceComponent: rightDrawer.panelContent
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
                    // Gives way to the page tabs while the centre panel is open:
                    // rises towards the screen's edge as it fades.
                    opacity:   1 - centerDrawer.chips
                    enabled:   centerDrawer.chips < 0.5
                    visible:   opacity > 0
                    transform: Translate { y: -centerDrawer.chips * Theme.centerDropdown.swapRise }
                }

                // ── Page tabs, where the chips were ───────────────────────────
                PageTabs {
                    x:      barWindow._cx - width / 2
                    width:  barWindow._cBody
                    height: parent.height
                    z:      2
                    drawer: centerDrawer
                    pages:  root.centerTabs
                    rise:   Theme.centerDropdown.swapRise
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
