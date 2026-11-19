pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes

import qs.themes

// A ring that fills clockwise from the top: a fraction of a whole, with a value in its centre and a label
// below it.
//
//   CircularGauge { fraction: 0.66; color: …; value: "66°"; label: "k10temp Tctl" }
Item {
    id: root

    property real fraction: 0        // [0–1], clamped
    property color color: Theme.colors.primary
    property string value: ""
    property string label: ""
    property string sublabel: ""
    property real size: 56
    property real thickness: 5
    property bool selected: false

    signal clicked()

    implicitWidth:  Math.max(size, 72)
    implicitHeight: size + 4 + labelText.implicitHeight + (sublabel !== "" ? subText.implicitHeight : 0)

    readonly property real _fraction: Math.max(0, Math.min(1, fraction))

    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: 8
        color: root.selected ? Theme.widget.activeBackground : mouse.containsMouse ? Theme.widget.hoverBackground : "transparent"
    }

    Item {
        id: ring
        width: root.size
        height: root.size
        anchors.horizontalCenter: parent.horizontalCenter

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            // Track
            ShapePath {
                strokeColor: Theme.colors.outline
                strokeWidth: root.thickness
                fillColor:   "transparent"
                capStyle:    ShapePath.RoundCap

                PathAngleArc {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    radiusX: (ring.width - root.thickness) / 2
                    radiusY: (ring.height - root.thickness) / 2
                    startAngle: -90
                    sweepAngle: 360
                }
            }

            // Fill
            ShapePath {
                strokeColor: root.color
                strokeWidth: root.thickness
                fillColor:   "transparent"
                capStyle:    ShapePath.RoundCap

                PathAngleArc {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    radiusX: (ring.width - root.thickness) / 2
                    radiusY: (ring.height - root.thickness) / 2
                    startAngle: -90
                    sweepAngle: Math.max(0.5, root._fraction * 360)

                    Behavior on sweepAngle { NumberAnimation { duration: Theme.animation.duration } }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text:           root.value
            color:          root.color
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSizeSmall
            font.bold:      true

            Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
        }
    }

    Text {
        id: labelText
        anchors.top: ring.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        width:               root.width
        horizontalAlignment: Text.AlignHCenter
        elide:               Text.ElideRight
        text:                root.label
        color:               Theme.widget.textColor
        font.family:         Theme.widget.fontFamily
        font.pixelSize:      Theme.widget.fontSizeSmall - 1
    }

    Text {
        id: subText
        visible: root.sublabel !== ""
        anchors.top: labelText.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width:               root.width
        horizontalAlignment: Text.AlignHCenter
        elide:               Text.ElideRight
        text:                root.sublabel
        color:               Theme.widget.textColorDim
        font.family:         Theme.widget.fontFamily
        font.pixelSize:      Theme.widget.fontSizeSmall - 2
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.clicked()
    }
}
