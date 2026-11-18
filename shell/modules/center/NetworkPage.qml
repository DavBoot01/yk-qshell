pragma ComponentBehavior: Bound

import QtQuick
import qs.themes
import qs.services

// NetworkPage — network connection detail view.
//
// Shows connection type, SSID/name, IP address, WiFi signal bars,
// and live upload/download traffic with auto-scaling units.
Item {
    id: root

    // Format bytes/s → "X.X KB/s" / "X.X MB/s" / "X B/s"
    function _fmtBps(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + " MB/s"
        if (bps >= 1024)    return (bps / 1024).toFixed(1)    + " KB/s"
        return bps + " B/s"
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    Column {
        anchors {
            top:    parent.top
            left:   parent.left
            right:  parent.right
            bottom: parent.bottom
            margins: 12
        }
        spacing: 12

        // ── Status + SSID ─────────────────────────────────────────────────────
        Row {
            width:   parent.width
            spacing: 8
            anchors.horizontalCenter: parent.horizontalCenter

            // Status dot
            Rectangle {
                width:           10
                height:          10
                radius:          5
                anchors.verticalCenter: parent.verticalCenter
                color:           Network.connected ? Theme.widget.colorOk : Theme.widget.colorCritical

                Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
            }

            // Connection name / SSID
            Text {
                text:           Network.connected
                                ? (Network.ssid !== "" ? Network.ssid : Network.type)
                                : Translation.tr("Disconnected")
                color:          Theme.widget.textColor
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeLarge
                font.bold:      true
                elide:          Text.ElideRight
                width:          parent.width - 18
            }
        }

        // ── Connection type tag ───────────────────────────────────────────────
        Text {
            visible:        Network.connected
            text:           Network.type === "wifi" ? Translation.tr("Wi-Fi") : Translation.tr("Ethernet")
            color:          Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSizeSmall
        }

        // ── WiFi signal bars ──────────────────────────────────────────────────
        Row {
            visible:        Network.connected && Network.type === "wifi"
            width:          parent.width
            spacing:        0

            // 5 bars of increasing height; active if signal > threshold
            Row {
                spacing: 3

                Repeater {
                    model: 5
                    delegate: Item {
                        required property int index
                        readonly property int _threshold: (index + 1) * 20
                        readonly property bool _active:   Network.wifiSignal >= _threshold

                        width:  8
                        height: 20
                        anchors.bottom: parent ? parent.bottom : undefined

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width:          parent.width
                            height:         6 + parent.index * 3
                            radius:         2
                            color:          parent._active ? Theme.colors.primary : Theme.colors.outline

                            Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
                        }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           "  " + Network.wifiSignal + " %"
                color:          Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall
            }
        }

        // ── IP address ────────────────────────────────────────────────────────
        Row {
            visible: Network.connected && Network.ipAddress !== ""
            spacing: 6

            Text {
                text:           Translation.tr("IP")
                color:          Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall
                font.bold:      true
            }
            Text {
                text:           Network.ipAddress
                color:          Theme.widget.textColor
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall
            }
        }

        // ── Separator ─────────────────────────────────────────────────────────
        Rectangle {
            visible: Network.connected
            width:   parent.width
            height:  1
            color:   Theme.colors.outline
            opacity: 0.5
        }

        // ── Traffic ───────────────────────────────────────────────────────────
        Row {
            visible: Network.connected
            width:   parent.width

            // Download
            Column {
                width:   parent.width / 2
                spacing: 2

                Text {
                    text:           "↓  Download"
                    color:          Theme.widget.textColorDim
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSizeSmall
                }
                Text {
                    text:           root._fmtBps(Network.rxBytesPerSec)
                    color:          Theme.widget.textColor
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSize
                    font.bold:      true
                }
            }

            // Upload
            Column {
                width:   parent.width / 2
                spacing: 2

                Text {
                    text:           "↑  Upload"
                    color:          Theme.widget.textColorDim
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSizeSmall
                }
                Text {
                    text:           root._fmtBps(Network.txBytesPerSec)
                    color:          Theme.widget.textColor
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSize
                    font.bold:      true
                }
            }
        }
    }
}
