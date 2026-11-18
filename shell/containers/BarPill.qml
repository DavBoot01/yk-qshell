pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

import qs.themes

// BarPill — a single pill-shaped container with configurable style mode.
//
// Style modes (styleMode property):
//   "solid"       — filled Rectangle at backgroundOpacity + border
//   "blur"        — tinted fill (backgroundOpacity) + layer.effect blur hint + border
//   "outline"     — transparent fill, border only
//   "transparent" — no fill, no border, content only
//
// Sizing:
//   Height is fixed: Theme.sizes.barHeight − Theme.bar.pill.verticalMargin * 2
//   Width adapts to content: contentLoader.implicitWidth + horizontalPadding * 2,
//   floored at Theme.bar.pill.minWidth. Width changes animate via Behavior.
//   With Theme.bar.pill.holdWidth the width only grows at once; it shrinks
//   after the content has stayed narrower for holdRelease ms. The content
//   then sits at `contentAlign` inside the held room.
//
// Usage:
//   BarPill {
//       content: Component { Text { text: "Hello" } }
//       styleMode: "outline"
//   }
Item {
    id: root

    // Required: the widget to load inside this pill.
    required property Component content

    // Screen this pill is rendered on — set by BarContainer.
    // Propagated down to BarChip via the parent chain so chips can pass
    // the correct screen to PanelManager when opening overlay panels.
    property var screen: null

    // Style knobs — all default from Theme.bar.pill.*
    property string styleMode:         Theme.bar.pill.defaultStyle
    property color  background:        Theme.bar.pill.background
    property real   backgroundOpacity: Theme.bar.pill.backgroundOpacity
    property color  borderColor:       Theme.bar.pill.borderColor
    property real   borderWidth:       Theme.bar.pill.borderWidth
    property real   radius:            Theme.bar.pill.radius
    property real   horizontalPadding: Theme.bar.pill.horizontalPadding

    // "left" | "center" | "right" — where the content sits when the pill is
    // wider than it (held width). Side pills align to the screen's side.
    property string contentAlign: "center"

    // ── Sizing ────────────────────────────────────────────────────────────────

    // Height is fixed; widgets must adapt to it, not define it.
    height: Theme.sizes.barHeight - Theme.bar.pill.verticalMargin * 2

    // Width the content asks for, never narrower than minWidth.
    readonly property real _natural: Math.max(
        contentLoader.implicitWidth + root.horizontalPadding * 2,
        Theme.bar.pill.minWidth
    )

    // Widest width held (holdWidth); follows _natural up at once, down only
    // when _releaseTimer fires.
    property real _held: 0

    on_NaturalChanged: {
        if (root._natural >= root._held) {
            root._held = root._natural
            _releaseTimer.stop()
        } else if (!_releaseTimer.running) {
            _releaseTimer.start()
        }
    }

    Timer {
        id: _releaseTimer
        interval: Theme.bar.pill.holdRelease
        onTriggered: root._held = root._natural
    }

    width: Theme.bar.pill.holdWidth ? Math.max(root._held, root._natural) : root._natural

    Behavior on width {
        NumberAnimation {
            duration:    Theme.bar.pill.widthAnimationDuration
            easing.type: Theme.bar.pill.widthAnimationEasing
        }
    }

    // ── Background ────────────────────────────────────────────────────────────

    Rectangle {
        id: pillBackground
        anchors.fill: parent
        radius: root.radius

        // solid / blur → filled; outline / transparent → no fill
        color: (root.styleMode === "solid" || root.styleMode === "blur")
               ? Qt.rgba(root.background.r, root.background.g, root.background.b,
                         root.backgroundOpacity)
               : "transparent"

        // transparent → no border; all others → border visible
        border.color: root.styleMode !== "transparent" ? root.borderColor : "transparent"
        border.width: root.styleMode !== "transparent" ? root.borderWidth : 0

        // blur mode: render pill to its own layer so the compositor can detect
        // the region for blur, and add a QML-side blur hint via MultiEffect.
        // Activate compositor blur with a Hyprland layerrule:
        //   layerrule = blur, ^(myshell:bar)$
        layer.enabled: root.styleMode === "blur"
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax:     Theme.bar.pill.blurRadius
            blur:        1.0
        }
    }

    // ── Content ───────────────────────────────────────────────────────────────

    // Loader height is pinned to the pill height — widgets must fit within it.
    Loader {
        id: contentLoader
        anchors.verticalCenter: parent.verticalCenter
        x: root.contentAlign === "left"  ? root.horizontalPadding
         : root.contentAlign === "right" ? root.width - root.horizontalPadding - width
         : Math.round((root.width - width) / 2)
        height: root.height
        sourceComponent: root.content
    }
}
