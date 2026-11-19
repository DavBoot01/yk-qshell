pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs
import qs.themes
import qs.services

// RightPanel — the right side panel's pages.
//
// Four pages: "audio", "wifi", "bluetooth" and "clock", each opened by its own
// chip in the bar, so the panel carries no tabs of its own. The page shown is
// PanelManager.activeContentId; a StackLayout swaps AudioPanel, WiFiPanel,
// BluetoothPanel and ClockPage.
//
// `preferredHeight` is the shown page's: the panel fits it.
Item {
    id: root

    implicitWidth:  parent ? parent.width  : 0
    implicitHeight: parent ? parent.height : 0

    readonly property real preferredHeight: {
        const page = pages.children[pages.currentIndex]
        return page && page.preferredHeight !== undefined ? page.preferredHeight : 0
    }

    // The page shown, kept while the panel closes and the manager has let go.
    property string _page: PanelManager.activeContentId
    Connections {
        target: PanelManager
        function onActiveContentIdChanged(): void {
            if (PanelManager.activePanelId === "side-right")
                root._page = PanelManager.activeContentId
        }
    }

    // ── Content area ──────────────────────────────────────────────────────────
    StackLayout {
        id: pages
        anchors.fill: parent

        currentIndex: root._page === "wifi" ? 1
                    : root._page === "bluetooth" ? 2
                    : root._page === "clock" ? 3 : 0

        AudioPanel     {}
        WiFiPanel      {}
        BluetoothPanel {}
        ClockPage      {}
    }
}
