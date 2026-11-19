pragma ComponentBehavior: Bound

import QtQuick
import qs.themes

// CalCell — a day, a month or a year: today's filled, the selected one ringed.
Item {
    id: c
    property alias text: label.text
    property bool round:   false
    property bool outside: false
    property bool current: false
    property bool chosen:  false
    signal clicked()

    Rectangle {
        anchors.centerIn: parent
        height: c.round ? Math.min(parent.width, parent.height) - 2 : parent.height - 4
        width:  c.round ? height : parent.width - 8
        radius: c.round ? height / 2 : 10
        color: c.current ? Qt.rgba(Theme.colors.primary.r, Theme.colors.primary.g, Theme.colors.primary.b, 0.22)
             : cellMouse.containsMouse ? Theme.widget.hoverBackground : "transparent"
        border.width: c.chosen ? 1.5 : 0
        border.color: Theme.colors.primary
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: c.current || c.chosen ? Theme.colors.primary : Theme.widget.textColor
        opacity: c.outside ? 0.35 : 1
        font.family:    Theme.widget.fontFamily
        font.pixelSize: c.round ? Theme.widget.fontSizeSmall : Theme.widget.fontSize
        font.bold:      c.current
    }

    MouseArea {
        id: cellMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    c.clicked()
    }
}
