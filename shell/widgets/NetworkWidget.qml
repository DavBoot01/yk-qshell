pragma ComponentBehavior: Bound

import QtQuick

import qs.themes

// Displays network connection and live traffic.
//
// Line 1: type icon + connection name (SSID or ethernet name).
//         For wifi the icon reflects signal strength; color follows thresholds.
// Line 2: ↓ rx  ↑ tx — auto-scaled to B/s · KB/s · MB/s.
//
// Bind from Network service:
//   connected      Network.connected
//   type           Network.type
//   ssid           Network.ssid
//   wifiSignal     Network.wifiSignal
//   rxBytesPerSec  Network.rxBytesPerSec
//   txBytesPerSec  Network.txBytesPerSec
Item {
    id: root

    property bool   connected:    false
    property string type:         "none"
    property string ssid:         ""
    property int    wifiSignal:   0
    property int    rxBytesPerSec: 0
    property int    txBytesPerSec: 0

    implicitWidth:  Math.max(topRow.implicitWidth, trafficRow.implicitWidth)
    implicitHeight: topRow.implicitHeight + 1 + trafficRow.implicitHeight

    // ── Helpers ───────────────────────────────────────────────────────────────

    // Nerd Font wifi glyphs by signal strength bucket.
    readonly property string _wifiIcon:
        !root.connected      ? "󰤮" :
        root.wifiSignal >= 75 ? "󰤨" :
        root.wifiSignal >= 50 ? "󰤥" :
        root.wifiSignal >= 25 ? "󰤢" :
                                "󰤟"

    readonly property string _icon:
        root.type === "wifi"     ? root._wifiIcon :
        root.type === "ethernet" ? "󰈀"            :
                                   "󰤮"

    // Signal color for wifi; neutral for ethernet / none.
    readonly property color _iconColor:
        root.type !== "wifi"      ? Theme.widget.textColorDim  :
        root.wifiSignal >= 50     ? Theme.widget.textColorDim  :
        root.wifiSignal >= 25     ? Theme.widget.colorWarn     :
                                    Theme.widget.colorCritical

    function _fmt(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + " MB/s"
        if (bps >= 1024)    return (bps / 1024).toFixed(1)    + " KB/s"
        return bps + " B/s"
    }

    // ── Line 1: icon + name ───────────────────────────────────────────────────
    Row {
        id: topRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4

        Text {
            text:           root._icon
            color:          root._iconColor
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: Theme.animation.duration }
            }
        }

        Text {
            text:           root.connected ? root.ssid : "—"
            color:          root.connected ? Theme.widget.textColor : Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            font.bold:      true
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── Line 2: rx / tx ───────────────────────────────────────────────────────
    Row {
        id: trafficRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: topRow.bottom
        anchors.topMargin: 1
        spacing: 6

        Text {
            text:           "↓ " + root._fmt(root.rxBytesPerSec)
            color:          Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSizeSmall
        }

        Text {
            text:           "↑ " + root._fmt(root.txBytesPerSec)
            color:          Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSizeSmall
        }
    }
}
