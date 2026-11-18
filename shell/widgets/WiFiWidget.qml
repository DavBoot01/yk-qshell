pragma ComponentBehavior: Bound

import QtQuick

import qs.themes

// WiFiWidget — compact network indicator for the bar chip.
//
// Shows a signal-strength icon and the SSID (or connection type).
// Presentational: values are bound by the parent (root.*).
Item {
    id: root

    property bool   connected:  false
    property string type:       "none"   // "wifi" | "ethernet" | "none"
    property string ssid:       ""
    property int    wifiSignal: 0

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        // Signal / type icon
        Text {
            text:
                !root.connected       ? "󰤮" :
                root.type === "ethernet" ? "󰈀" :
                root.wifiSignal >= 75  ? "󰤨" :
                root.wifiSignal >= 50  ? "󰤥" :
                root.wifiSignal >= 25  ? "󰤢" :
                                            "󰤟"

            color:
                !root.connected        ? Theme.widget.textColorDim :
                root.type !== "wifi"   ? Theme.widget.textColorDim :
                root.wifiSignal >= 50  ? Theme.widget.textColor    :
                root.wifiSignal >= 25  ? Theme.widget.colorWarn    :
                                            Theme.widget.colorCritical

            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
        }

        // SSID or connection label
        Text {
            text:
                !root.connected       ? "—" :
                root.type === "wifi"     ? root.ssid :
                                             "Ethernet"

            color:          root.connected
                ? Theme.widget.textColorDim
                : Theme.widget.textColorDim

            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            anchors.verticalCenter: parent.verticalCenter

            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
