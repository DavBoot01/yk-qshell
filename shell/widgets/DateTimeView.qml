import QtQuick

import qs.themes

// Displays current time and date.
// Bind hours/minutes/seconds/date from DateTime service in the parent.
//
// Time line: HH:mm in bold, :ss dimmed and smaller — visually subordinate.
// Date line: compact string below (e.g. "Mon 13 Apr").
Item {
    id: root

    property int    hours:   0
    property int    minutes: 0
    property int    seconds: 0
    property string date:    ""

    implicitWidth:  column.implicitWidth
    implicitHeight: column.implicitHeight

    Column {
        id: column
        anchors.centerIn: parent
        spacing: 1

        // ── Time ─────────────────────────────────────────────────────────────
        // Item instead of Row so siblings can use anchors freely.
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth:  timeText.implicitWidth + secsText.implicitWidth
            implicitHeight: timeText.implicitHeight

            Text {
                id: timeText
                anchors.left:           parent.left
                anchors.verticalCenter: parent.verticalCenter
                text:            Qt.formatTime(new Date(0, 0, 0, root.hours, root.minutes), "HH:mm")
                color:           Theme.widget.textColor
                font.family:     Theme.widget.fontFamily
                font.pixelSize:  Theme.widget.fontSize
                font.bold:       true
            }

            Text {
                id: secsText
                anchors.left:   timeText.right
                anchors.bottom: timeText.bottom
                text:           ":" + String(root.seconds).padStart(2, "0")
                color:          Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall
            }
        }

        // ── Date ─────────────────────────────────────────────────────────────
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           root.date
            color:          Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSizeSmall
        }
    }
}
