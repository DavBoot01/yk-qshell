pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

import qs.themes
import qs.services

// BarChip — per-item visual wrapper inside a BarPill.
//
// Provides individual background, border, and radius for a single widget.
// Multiple chips coexist inside the same pill, each with its own chrome.
//
// ── Panel trigger (optional) ──────────────────────────────────────────────────
// Set panelId + panelContentId + panelContent to make the chip open/close an
// overlay panel when clicked.  The chip automatically highlights when its panel
// is the active one.
//
//   BarChip {
//       panelId:        "center-dropdown"
//       panelContentId: "network"
//       panelContent:   Component { NetworkDetailPanel {} }
//       content: Component { NetworkWidget { … } }
//   }
//
// ── Style modes ───────────────────────────────────────────────────────────────
//   "solid"       — filled Rectangle + border
//   "blur"        — tinted fill + layer.effect blur hint + border
//   "outline"     — transparent fill, border only
//   "transparent" — no fill, no border, content only (default)
//
// ── Sizing ────────────────────────────────────────────────────────────────────
//   Width  = contentLoader.implicitWidth + horizontalPadding * 2
//   Height = contentLoader.implicitHeight
Item {
    id: root

    required property Component content

    // ── Visual style ──────────────────────────────────────────────────────────
    property string styleMode:         Theme.bar.chip.defaultStyle
    property color  background:        Theme.bar.chip.background
    property real   backgroundOpacity: Theme.bar.chip.backgroundOpacity
    property color  borderColor:       Theme.bar.chip.borderColor
    property real   borderWidth:       Theme.bar.chip.borderWidth
    property real   radius:            Theme.bar.chip.radius
    property real   horizontalPadding: Theme.bar.chip.horizontalPadding

    // ── Panel trigger (optional) ──────────────────────────────────────────────
    // Leave empty/null to keep the chip non-interactive.
    property string    panelId:        ""
    property string    panelContentId: ""
    property Component panelContent:   null

    // True when this chip's panel slot is currently the active one.
    readonly property bool panelActive: panelContent !== null
        && PanelManager.activePanelId   === root.panelId
        && PanelManager.activeContentId === root.panelContentId

    // Screen of the window hosting this chip (the per-screen bar window),
    // so overlays open only on the screen where the click happened.
    readonly property var _resolvedScreen: root.Window.window?.screen ?? null

    implicitWidth:  contentLoader.implicitWidth  + horizontalPadding * 2
    implicitHeight: contentLoader.implicitHeight

    // ── Background ────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: root.radius

        color: (root.styleMode === "solid" || root.styleMode === "blur")
               ? Qt.rgba(root.background.r, root.background.g, root.background.b,
                         root.backgroundOpacity)
               : "transparent"

        border.color: root.styleMode !== "transparent" ? root.borderColor : "transparent"
        border.width: root.styleMode !== "transparent" ? root.borderWidth : 0

        layer.enabled: root.styleMode === "blur"
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax:     Theme.bar.chip.blurRadius
            blur:        1.0
        }
    }

    // Active-state overlay — visible when this chip's panel is open.
    Rectangle {
        anchors.fill: parent
        radius:       root.radius
        color:        Theme.widget.activeBackground
        visible:      root.panelActive

        Behavior on opacity { NumberAnimation { duration: Theme.animation.duration } }
    }

    // ── Content ───────────────────────────────────────────────────────────────
    Loader {
        id: contentLoader
        anchors.centerIn: parent
        sourceComponent: root.content
    }

    // ── Interaction ───────────────────────────────────────────────────────────
    // Enabled only when a PanelManager panel is wired.
    MouseArea {
        anchors.fill: parent
        enabled:      root.panelContent !== null
        cursorShape:  Qt.PointingHandCursor
        hoverEnabled: true

        property bool _hovered: false
        onEntered: _hovered = true
        onExited:  _hovered = false

        onClicked: {
            PanelManager.toggle(root.panelId, root.panelContentId, root.panelContent, root._resolvedScreen)
        }

        // Subtle hover tint
        Rectangle {
            anchors.fill: parent
            radius:       root.radius
            color:        Theme.widget.hoverBackground
            visible:      parent._hovered && !root.panelActive
        }
    }
}
