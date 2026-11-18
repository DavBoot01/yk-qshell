pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs
import qs.themes
import qs.services

// RightPanel — tab host for the right side panel.
//
// Two tabs: "audio" and "wifi".
// Active tab is PanelManager.activeContentId ("audio" | "wifi").
// Content area swaps between AudioPanel and WiFiPanel via a StackLayout.
Item {
    id: root

    implicitWidth:  parent ? parent.width  : 0
    implicitHeight: parent ? parent.height : 0

    // ── Tab bar ───────────────────────────────────────────────────────────────
    Row {
        id: tabBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 36
        spacing: 4

        Repeater {
            model: [
                { id: "audio", icon: "󰕾", label: "Audio" },
                { id: "wifi",  icon: "󰖩",  label: "Wi-Fi" }
            ]

            delegate: Item {
                id: tabDelegate
                required property var modelData
                readonly property bool _active: PanelManager.activeContentId === tabDelegate.modelData.id

                width:  (tabBar.width - tabBar.spacing) / 2
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

        currentIndex: PanelManager.activeContentId === "wifi" ? 1 : 0

        AudioPanel {}
        WiFiPanel  {}
    }
}
