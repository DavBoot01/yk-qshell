pragma ComponentBehavior: Bound

import QtQuick

import qs.themes

// BluetoothWidget — compact Bluetooth indicator for the bar chip.
//
// Off, on, or on with devices connected (their count beside the icon); a pairing waiting for the person
// shows in the warning colour. Presentational: values are bound by the parent.
Item {
    id: root

    property bool available: false
    property bool powered:   false
    property int  connected: 0
    property bool asking:    false

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight
    visible: root.available

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: !root.powered ? "󰂲" : root.connected > 0 ? "󰂱" : "󰂯"
            color: root.asking ? Theme.widget.colorWarn
                 : root.connected > 0 ? Theme.widget.textColor
                 : Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
        }

        Text {
            visible: root.powered && root.connected > 0
            text: root.connected
            color: Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
