pragma ComponentBehavior: Bound

import QtQuick

import qs.themes

// Displays aggregate CPU usage and a per-core minimap.
//
// Line 1: glyph + total percentage, color-coded by threshold.
// Line 2: one dot per core; opacity encodes per-core usage (dim = idle, opaque = busy).
//
// Bind from SystemStats:
//   totalPercent: SystemStats.cpuTotal
//   corePercents: SystemStats.cpuCores
Item {
    id: root

    property int totalPercent: 0
    property var corePercents: []

    implicitWidth:  Math.max(topRow.implicitWidth, coreMap.implicitWidth)
    implicitHeight: topRow.implicitHeight + 3 + coreMap.implicitHeight

    // ── Threshold color ───────────────────────────────────────────────────────
    readonly property color _valueColor:
        root.totalPercent >= 90 ? Theme.widget.colorCritical :
        root.totalPercent >= 70 ? Theme.widget.colorWarn     :
                                  Theme.widget.textColor

    // ── Line 1: glyph + total% ────────────────────────────────────────────────
    Row {
        id: topRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4

        Text {
            text:           "󰻠"
            color:          Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text:           root.totalPercent + "%"
            color:          root._valueColor
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            font.bold:      true
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: Theme.animation.duration }
            }
        }
    }

    // ── Line 2: per-core minimap ──────────────────────────────────────────────
    // Each dot: 4 × 4 px, opacity = 0.15 (idle) … 1.0 (full load).
    Row {
        id: coreMap
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: topRow.bottom
        anchors.topMargin: 3
        spacing: 2

        Repeater {
            model: root.corePercents
            delegate: Rectangle {
                required property int modelData

                width:  4
                height: 4
                radius: 1
                color:  modelData >= 90 ? Theme.widget.colorCritical :
                        modelData >= 70 ? Theme.widget.colorWarn     :
                                          Theme.widget.textColor
                opacity: 0.15 + (modelData / 100) * 0.85

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
