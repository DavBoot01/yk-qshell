pragma ComponentBehavior: Bound

import QtQuick
import qs.themes

// CalButton — a header button: the title, Today, an arrow.
Item {
    id: b
    property alias text:      label.text
    property bool  bold:      false
    property bool  square:    false
    property int   pixelSize: Theme.widget.fontSizeSmall
    signal clicked()

    implicitWidth:  b.square ? 26 : label.implicitWidth + 16
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: buttonMouse.containsMouse && b.enabled ? Theme.widget.hoverBackground : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: Theme.widget.textColor
        font.family:    Theme.widget.fontFamily
        font.pixelSize: b.pixelSize
        font.bold:      b.bold
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled:      b.enabled
        cursorShape:  Qt.PointingHandCursor
        onClicked:    b.clicked()
    }
}
