pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

import qs.themes

// Single system tray icon button.
//
// ── Interactions ──────────────────────────────────────────────────────────────
//   Left click   → item.activate()   (primary action defined by the app)
//   Right click  → opens DBus context menu if item.hasMenu
//
// ── Visual states ─────────────────────────────────────────────────────────────
//   NeedsAttention  — icon pulses (opacity animation)
//   Passive         — icon at reduced opacity (background service indicator)
//   Active          — normal opacity
//
// Usage:
//   TrayIcon { required property SystemTrayItem item }
Item {
    id: root

    required property SystemTrayItem item

    implicitWidth:  28
    implicitHeight: 28

    // ── Hover background (same style as LauncherButton) ───────────────────────
    Rectangle {
        anchors.fill:    parent
        anchors.margins: 2
        radius:  Theme.rounding.button
        color:   mouse.containsMouse ? Theme.widget.hoverBackground : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.animation.duration }
        }
    }

    // ── Icon ──────────────────────────────────────────────────────────────────
    Image {
        id: icon
        anchors.centerIn: parent
        width:    18
        height:   18
        source:   root.item.icon
        fillMode: Image.PreserveAspectFit
        smooth:   true

        // Passive items are dimmed; others are fully opaque (modulated by pulse).
        opacity: root.item.status === Status.Passive ? 0.45 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animation.duration }
        }
    }

    // ── NeedsAttention pulse ──────────────────────────────────────────────────
    SequentialAnimation {
        running:  root.item.status === Status.NeedsAttention
        loops:    Animation.Infinite

        NumberAnimation {
            target:   icon
            property: "opacity"
            to:       0.3
            duration: 600
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target:   icon
            property: "opacity"
            to:       1.0
            duration: 600
            easing.type: Easing.InOutSine
        }
    }

    // ── Input ─────────────────────────────────────────────────────────────────
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: event => {
            if (event.button === Qt.RightButton) {
                if (root.item.hasMenu) trayMenu.open()
            } else {
                root.item.activate()
            }
        }
    }

    // ── Context menu ──────────────────────────────────────────────────────────
    QsMenuAnchor {
        id: trayMenu
        menu: root.item.menu
        anchor.item:    root
        anchor.gravity: Edges.Bottom
        anchor.edges:   Edges.Bottom
    }
}
