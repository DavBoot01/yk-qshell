pragma ComponentBehavior: Bound

import QtQuick

import qs.themes

// AudioWidget — compact volume indicator for the bar chip.
//
// Shows a Nerd Font volume icon and the current volume percentage.
// Presentational: values are bound by the parent (root.volume / .muted).
//
// Bind to a BarChip and toggle the right panel via PanelManager
// (handled by the BarChip / Bar.qml, not here).
Item {
    id: root

    property int  volume: 0
    property bool muted:  false

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        // Volume icon
        Text {
            text:
                root.muted      ? "󰖁" :
                root.volume === 0 ? "󰕿" :
                root.volume < 50  ? "󰖀" :
                                            "󰕾"

            color: root.muted
                ? Theme.widget.colorWarn
                : Theme.widget.textColor

            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
        }

        // Percentage
        Text {
            text:           root.volume + "%"
            color:          root.muted
                ? Theme.widget.colorWarn
                : Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
        }
    }
}
