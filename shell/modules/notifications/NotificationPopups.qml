pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.themes
import qs.services

// NotificationPopups — a notification over the screen as it comes, top right under the bar, on the focused
// monitor.
//
// A popup shows what Notifications.arrived hands it, newest on top, at most `kept` at once. It leaves when
// its time runs out — the application's `expire_ms`, or `timeout` — and stays while the pointer is on it; a
// critical one, or one whose application asked for no expiry, stays until it is answered or dismissed.
// Leaving the screen is not leaving the list: the notification stays in the right panel until dismissed.
// None pops up under do-not-disturb (the Plugin marks those `quiet`), nor while the right panel shows them.
PanelWindow {
    id: win

    // How long a popup stays where the application does not say, and how many at once.
    property int timeout: 6000
    property int kept: 4

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    WlrLayershell.namespace: "myshell:notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors { top: true; right: true }
    margins { top: Theme.sizes.barHeight + 10; right: 12 }
    implicitWidth: 380
    implicitHeight: Math.max(1, list.contentHeight + 12)
    visible: popups.count > 0

    // The notifications shown, by id: the model holds ids, so that a replacement updates its card in place.
    property var _byId: ({})
    ListModel { id: popups }

    readonly property bool _panelShows: PanelManager.activePanelId === "side-right"
        && PanelManager.activeContentId === "clock"

    function _remove(id: int): void {
        for (let i = 0; i < popups.count; i++) {
            if (popups.get(i).nid === id) {
                popups.remove(i);
                return;
            }
        }
    }

    Connections {
        target: Notifications
        function onArrived(n: var): void {
            if (n.quiet || win._panelShows)
                return;
            const byId = Object.assign({}, win._byId);
            byId[n.id] = n;
            win._byId = byId;
            for (let i = 0; i < popups.count; i++) {
                if (popups.get(i).nid === n.id) {
                    popups.setProperty(i, "stamp", n.at);
                    return;
                }
            }
            popups.insert(0, { "nid": n.id, "stamp": n.at });
            while (popups.count > win.kept)
                popups.remove(popups.count - 1);
        }
        // Gone from the list — dismissed here, in the panel, or closed by its application: gone from the screen.
        function onListChanged(): void {
            const ids = {};
            for (const n of Notifications.list)
                ids[n.id] = true;
            for (let i = popups.count - 1; i >= 0; i--) {
                if (!ids[popups.get(i).nid])
                    popups.remove(i);
            }
        }
    }

    // Opening the panel takes them off the screen: they are all there.
    on_PanelShowsChanged: if (_panelShows) popups.clear()

    ListView {
        id: list
        anchors { fill: parent; topMargin: 2; leftMargin: 6; rightMargin: 6 }
        interactive: false
        spacing: 8
        model: popups

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x"; from: 60; to: 0; duration: 380; easing.type: Easing.OutQuart }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 260; easing.type: Easing.OutQuad }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x"; to: 80; duration: 260; easing.type: Easing.InQuad }
                NumberAnimation { property: "opacity"; to: 0; duration: 220 }
            }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 300; easing.type: Easing.OutQuart }
        }

        delegate: NotificationCard {
            id: popup
            required property int nid
            required property real stamp

            width: list.width
            popup: true
            notification: win._byId[nid] ?? { id: nid, summary: "", body: "", actions: [], at: stamp }
            onActed: win._remove(nid)

            readonly property int _life: notification.urgency === "critical" || notification.expire_ms === 0 ? 0
                : notification.expire_ms > 0 ? notification.expire_ms : win.timeout

            Timer {
                id: life
                interval: popup._life
                running: popup._life > 0 && !popup.hovered
                onTriggered: win._remove(popup.nid)
            }
            // A replacement shows again for its whole time.
            onStampChanged: if (life.running) life.restart()
        }
    }
}
