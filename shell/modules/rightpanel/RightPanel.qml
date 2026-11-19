pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs
import qs.themes
import qs.services

// RightPanel — tab host for the right side panel.
//
// Three tabs: "audio", "wifi" and "bluetooth".
// Active tab is PanelManager.activeContentId ("audio" | "wifi" | "bluetooth").
// Content area swaps between AudioPanel, WiFiPanel and BluetoothPanel via a StackLayout.
Item {
    id: root

    implicitWidth:  parent ? parent.width  : 0
    implicitHeight: parent ? parent.height : 0

    // The page shown, kept while the panel closes and the manager has let go.
    property string _page: PanelManager.activeContentId
    Connections {
        target: PanelManager
        function onActiveContentIdChanged(): void {
            if (PanelManager.activePanelId === "side-right")
                root._page = PanelManager.activeContentId
        }
    }

    // ── Tab bar ───────────────────────────────────────────────────────────────
    Row {
        id: tabBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 36
        spacing: 4

        Repeater {
            model: [
                { id: "audio", icon: "󰕾", label: "Audio" },
                { id: "wifi",  icon: "󰖩",  label: "Wi-Fi" },
                { id: "bluetooth", icon: "󰂯", label: "Bluetooth" }
            ]

            delegate: Item {
                id: tabDelegate
                required property var modelData
                readonly property bool _active: PanelManager.activeContentId === tabDelegate.modelData.id

                width:  (tabBar.width - 2 * tabBar.spacing) / 3
                height: tabBar.height

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.rounding.button
                    color: tabDelegate._active
                        ? Theme.widget.activeBackground
                        : tabHover.containsMouse
                            ? Theme.widget.hoverBackground
                            : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.animation.duration } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text:           tabDelegate.modelData.icon
                            color:          tabDelegate._active
                                ? Theme.colors.primary
                                : Theme.widget.textColorDim
                            font.family:    Theme.widget.fontFamily
                            font.pixelSize: Theme.widget.fontSize
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
                        }

                        Text {
                            text:           Translation.tr(tabDelegate.modelData.label)
                            color:          tabDelegate._active
                                ? Theme.widget.textColor
                                : Theme.widget.textColorDim
                            font.family:    Theme.widget.fontFamily
                            font.pixelSize: Theme.widget.fontSize
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
                        }
                    }
                }

                MouseArea {
                    id: tabHover
                    anchors.fill:  parent
                    hoverEnabled:  true
                    onClicked:     PanelManager.open("side-right", tabDelegate.modelData.id,
                                   PanelManager.activeContent, PanelManager.activeScreen)
                    cursorShape:   Qt.PointingHandCursor
                }
            }
        }
    }

    // ── Divider ───────────────────────────────────────────────────────────────
    Rectangle {
        id: divider
        anchors { top: tabBar.bottom; left: parent.left; right: parent.right }
        anchors.topMargin: 6
        height: 1
        color: Theme.colors.outline
        opacity: 0.5
    }

    // ── Content area ──────────────────────────────────────────────────────────
    StackLayout {
        anchors {
            top:    divider.bottom
            left:   parent.left
            right:  parent.right
            bottom: parent.bottom
        }
        anchors.topMargin: 10

        currentIndex: root._page === "wifi" ? 1
                    : root._page === "bluetooth" ? 2 : 0

        AudioPanel     {}
        WiFiPanel      {}
        BluetoothPanel {}
    }
}
