pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray

import qs.themes

// Full system tray row — renders one TrayIcon per tray item.
//
// ── Model ─────────────────────────────────────────────────────────────────────
//   model  — tray items to render; bind TrayService.items (all) or
//            TrayService.activeItems (hides Passive items).
//
// ── Empty state ───────────────────────────────────────────────────────────────
//   Collapses to zero width/height when there are no visible items,
//   so BarChip / BarPill adapt automatically.
//
// Usage:
//   TrayBar { model: TrayService.items }        — show all items
//   TrayBar { model: TrayService.activeItems }  — hide passive items
Item {
    id: root

    property var model: []

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.model

            delegate: TrayIcon {
                required property SystemTrayItem modelData
                item: modelData
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
