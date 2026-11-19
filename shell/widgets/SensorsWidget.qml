pragma ComponentBehavior: Bound

import QtQuick

import qs.themes

// Displays the CPU's temperature and a minimap of every temperature the host reads.
//
// Line 1: glyph + the CPU's temperature, coloured by the worst level among them.
// Line 2: one dot per temperature, hottest first; colour is its level, opacity how near its limit it is.
//
// Bind from Sensors:
//   celsius:      Sensors.cpuCelsius
//   level:        Sensors.level
//   temperatures: Sensors.temperatures
Item {
    id: root

    property int celsius: -1
    property string level: "normal"
    property var temperatures: []

    implicitWidth:  Math.max(topRow.implicitWidth, dotMap.implicitWidth)
    implicitHeight: topRow.implicitHeight + 3 + dotMap.implicitHeight

    function _colorOf(level: string): color {
        return level === "critical" ? Theme.widget.colorCritical :
               level === "high"     ? Theme.widget.colorWarn     :
                                      Theme.widget.textColor
    }

    // ── Line 1: glyph + °C ────────────────────────────────────────────────────
    Row {
        id: topRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4

        Text {
            text:           "󰔏"
            color:          Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text:           root.celsius >= 0 ? root.celsius + "°" : "—"
            color:          root._colorOf(root.level)
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            font.bold:      true
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: Theme.animation.duration }
            }
        }
    }

    // ── Line 2: one dot per temperature ───────────────────────────────────────
    // Opacity = 0.15 (cool) … 1.0 (at its limit); a sensor with no limit is scaled on 100 °C.
    Row {
        id: dotMap
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: topRow.bottom
        anchors.topMargin: 3
        spacing: 2

        Repeater {
            model: root.temperatures
            delegate: Rectangle {
                required property var modelData

                readonly property real _limit: modelData.critical || modelData.high || 100

                width:  4
                height: 4
                radius: 1
                color:  root._colorOf(modelData.level)
                opacity: 0.15 + Math.max(0, Math.min(1, modelData.value / _limit)) * 0.85

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animation.duration }
                }
                Behavior on color {
                    ColorAnimation { duration: Theme.animation.duration }
                }
            }
        }
    }
}
