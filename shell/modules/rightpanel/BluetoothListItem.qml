pragma ComponentBehavior: Bound

import QtQuick

import qs.themes
import qs.services

// BluetoothListItem — one device in the Bluetooth tab: its icon, its name, its battery where it reports
// one, and the action that fits it — connect or disconnect a paired device, pair one in range.
//
// Props: alias, icon (BlueZ's name for the kind), connected, paired, battery (-1 = none), busy
// Emits: activated() on the action, forgetRequested() on the secondary action of a paired device.
Item {
    id: root

    property string alias:     ""
    property string icon:      ""
    property bool   connected: false
    property bool   paired:    true
    property int    battery:   -1
    property bool   busy:      false

    signal activated()
    signal forgetRequested()

    implicitHeight: 44
    implicitWidth:  parent ? parent.width : 0

    readonly property string _glyph: {
        const i = root.icon || "";
        if (i.startsWith("audio-head"))  return "󰋋";
        if (i.startsWith("audio"))       return "󰓃";
        if (i.startsWith("input-mouse")) return "󰍽";
        if (i.startsWith("input-keyboard")) return "󰌌";
        if (i.startsWith("input-gaming")) return "󰊴";
        if (i.startsWith("phone"))       return "󰏲";
        if (i.startsWith("computer"))    return "󰟀";
        return "󰂯";
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.rounding.button
        color: root.connected
            ? Qt.rgba(Theme.colors.primary.r, Theme.colors.primary.g, Theme.colors.primary.b, 0.12)
            : rowHover.containsMouse ? Theme.widget.hoverBackground : "transparent"

        Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
    }

    Text {
        id: glyph
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        text: root._glyph
        color: root.connected ? Theme.colors.primary : Theme.widget.textColorDim
        font.family:    Theme.widget.fontFamily
        font.pixelSize: Theme.widget.fontSize
    }

    Column {
        anchors { left: glyph.right; leftMargin: 10; right: actions.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 1

        Text {
            width: parent.width
            text: root.alias
            color: Theme.widget.textColor
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: text !== ""
            text: root.busy ? Translation.tr("Working…")
                : root.connected && root.battery >= 0 ? Translation.tr("Connected") + " · " + root.battery + "%"
                : root.connected ? Translation.tr("Connected")
                : ""
            color: Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSizeSmall
            elide: Text.ElideRight
        }
    }

    Row {
        id: actions
        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
        spacing: 4

        Rectangle {
            visible: root.paired && !root.connected && rowHover.containsMouse
            width: 28; height: 26
            radius: Theme.rounding.button
            color: forgetHover.containsMouse ? Theme.widget.activeBackground : Theme.widget.hoverBackground
            Text {
                anchors.centerIn: parent
                text: "󰆴"
                color: Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall
            }
            MouseArea {
                id: forgetHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.forgetRequested()
            }
        }

        Rectangle {
            width: 86; height: 26
            radius: Theme.rounding.button
            opacity: root.busy ? 0.5 : 1
            color: actionHover.containsMouse ? Theme.widget.activeBackground : Theme.widget.hoverBackground
            Text {
                anchors.centerIn: parent
                text: !root.paired ? Translation.tr("Pair")
                    : root.connected ? Translation.tr("Disconnect")
                    : Translation.tr("Connect")
                color: Theme.widget.textColor
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall
            }
            MouseArea {
                id: actionHover
                anchors.fill: parent
                hoverEnabled: true
                enabled: !root.busy
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activated()
            }
        }
    }

    MouseArea {
        id: rowHover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
