import QtQuick
import QtQuick.Effects

import qs.themes

// Generic launcher trigger button.
// Emit `activated` when clicked; the parent is responsible for wiring
// this signal to the appropriate service (e.g. AppLauncher.launch()).
// Set `iconSource` to an image URL; if empty the icon area is hidden.
// Set `iconColor` to tint the SVG; defaults to Theme.widget.iconColor.
// Set `iconColor: "transparent"` to preserve the original SVG colors.
Item {
    id: root

    implicitWidth:  28
    implicitHeight: 28

    property string iconSource: ""
    property color  iconColor:  Theme.widget.iconColor

    signal activated()

    Rectangle {
        anchors.fill:    parent
        anchors.margins: 2
        radius: Theme.rounding.button
        color:  mouseArea.containsMouse ? Theme.widget.hoverBackground : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.animation.duration }
        }

        Image {
            anchors.centerIn: parent
            width:    18
            height:   18
            source:   root.iconSource
            visible:  root.iconSource !== ""
            fillMode: Image.PreserveAspectFit
            smooth:   true
            opacity:  mouseArea.containsMouse ? 1.0 : 0.75

            layer.enabled: root.iconColor.a > 0
            layer.effect: MultiEffect {
                colorization:      1.0
                colorizationColor: root.iconColor
            }

            Behavior on opacity {
                NumberAnimation { duration: Theme.animation.duration }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.activated()
    }
}
