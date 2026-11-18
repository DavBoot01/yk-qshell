pragma ComponentBehavior: Bound

import QtQuick

import qs.themes

// Displays RAM usage percentage and absolute used / total.
//
// Line 1: glyph + used percentage, color-coded by threshold.
// Line 2: "X.X / Y.Y GiB" (or MiB when total < 1 GiB).
//
// Bind from SystemStats:
//   usedPercent: SystemStats.ramUsedPercent
//   usedMiB:     SystemStats.ramUsedMiB
//   totalMiB:    SystemStats.ramTotalMiB
Item {
    id: root

    property int usedPercent: 0
    property int usedMiB:     0
    property int totalMiB:    0

    implicitWidth:  Math.max(topRow.implicitWidth, detailText.implicitWidth)
    implicitHeight: topRow.implicitHeight + 1 + detailText.implicitHeight

    // ── Threshold color ───────────────────────────────────────────────────────
    readonly property color _valueColor:
        root.usedPercent >= 90 ? Theme.widget.colorCritical :
        root.usedPercent >= 70 ? Theme.widget.colorWarn     :
                                 Theme.widget.textColor

    // ── Helpers ───────────────────────────────────────────────────────────────
    function _fmt(mib) {
        return mib >= 1024
            ? (mib / 1024).toFixed(1) + " GiB"
            : mib + " MiB"
    }

    // ── Line 1: glyph + used% ─────────────────────────────────────────────────
    Row {
        id: topRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4

        Text {
            text:           "󰍛"
            color:          Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text:           root.usedPercent + "%"
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

    // ── Line 2: used / total ──────────────────────────────────────────────────
    Text {
        id: detailText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: topRow.bottom
        anchors.topMargin: 1
        text:           root._fmt(root.usedMiB) + " / " + root._fmt(root.totalMiB)
        color:          Theme.widget.textColorDim
        font.family:    Theme.widget.fontFamily
        font.pixelSize: Theme.widget.fontSizeSmall
    }
}
