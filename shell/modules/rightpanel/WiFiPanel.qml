pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic as QC

import qs.themes
import qs.services

// WiFiPanel — scrollable list of nearby Wi-Fi networks.
//
// Reads WiFiService.networks for the list and Network.ssid for current status.
// Provides scan button and connect-on-tap via NetworkListItem.
Item {
    id: root

    implicitWidth:  parent ? parent.width  : 0
    implicitHeight: parent ? parent.height : 0

    // ── Header row: current connection + scan button ──────────────────────────
    Row {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 32
        spacing: 8

        // Connection status summary
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - scanBtn.width - parent.spacing
            text: Network.connected
                ? (Network.type === "wifi"
                    ? "󰖩  " + Network.ssid
                    : "󰈀  Ethernet")
                : "󰤮  Not connected"
            color:          Network.connected
                ? Theme.widget.textColor
                : Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            elide:          Text.ElideRight
        }

        // Scan button
        Rectangle {
            id: scanBtn
            width:  70
            height: 28
            anchors.verticalCenter: parent.verticalCenter
            radius: Theme.rounding.button
            color: WiFiService.scanning
                ? Theme.widget.subtleBackground
                : scanHover.containsMouse
                    ? Theme.widget.activeBackground
                    : Theme.widget.hoverBackground

            Behavior on color { ColorAnimation { duration: Theme.animation.duration } }

            Row {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text:           WiFiService.scanning ? "󰑓" : "󰑐"
                    color:          WiFiService.scanning
                        ? Theme.widget.textColorDim
                        : Theme.widget.textColor
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter

                    RotationAnimation on rotation {
                        running:  WiFiService.scanning
                        from:     0; to: 360
                        duration: 1000; loops: Animation.Infinite
                    }
                }

                Text {
                    text:           Translation.tr("Scan")
                    color:          WiFiService.scanning
                        ? Theme.widget.textColorDim
                        : Theme.widget.textColor
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: scanHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                enabled:      !WiFiService.scanning
                onClicked:    WiFiService.scan()
            }
        }
    }

    // ── Error banner ──────────────────────────────────────────────────────────
    Rectangle {
        id: errorBanner
        anchors { top: header.bottom; left: parent.left; right: parent.right }
        anchors.topMargin: 6
        height: visible ? 30 : 0
        visible: WiFiService.connectError !== ""
        radius: Theme.rounding.button
        color: Qt.rgba(
            Theme.widget.colorCritical.r,
            Theme.widget.colorCritical.g,
            Theme.widget.colorCritical.b, 0.15)

        Text {
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            text:           "󰀨  " + WiFiService.connectError
            color:          Theme.widget.colorCritical
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSizeSmall
            elide:          Text.ElideRight
            width:          parent.width - 16
        }
    }

    // ── Network list ──────────────────────────────────────────────────────────
    QC.ScrollView {
        anchors {
            top:    errorBanner.bottom
            left:   parent.left
            right:  parent.right
            bottom: parent.bottom
        }
        anchors.topMargin: errorBanner.visible ? 6 : 6
        clip: true

        // Hide the scrollbar chrome
        QC.ScrollBar.vertical.policy: QC.ScrollBar.AsNeeded
        QC.ScrollBar.horizontal.policy: QC.ScrollBar.AlwaysOff

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: WiFiService.networks

                delegate: NetworkListItem {
                    required property var modelData
                    width:    parent ? parent.width : 0
                    ssid:     modelData.ssid
                    signal:   modelData.signal
                    security: modelData.security
                    active:   modelData.active
                    onConnectRequested: ssid => WiFiService.connect(ssid)
                }
            }

            // Empty state
            Text {
                visible: WiFiService.networks.length === 0 && !WiFiService.scanning
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text:           Translation.tr("No networks found")
                color:          Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSize
                topPadding:     20
            }

            Text {
                visible: WiFiService.scanning
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text:           Translation.tr("Scanning…")
                color:          Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSize
                topPadding:     20
            }
        }
    }
}
