pragma ComponentBehavior: Bound

import QtQuick
import qs.themes
import qs.services

// ClockPage — large time display + current-month calendar.
//
// Updates time via DateTime service (every second).
// Updates calendar date via an internal 60-second timer (month changes).
Item {
    id: root

    // ── Date state ────────────────────────────────────────────────────────────
    property var _today: new Date()
    readonly property int _year:  _today.getFullYear()
    readonly property int _month: _today.getMonth()   // 0-based
    readonly property int _day:   _today.getDate()    // 1-based

    // Calendar grid cells: 0 = empty padding, 1-31 = day number.
    // Monday-first layout, padded to fill complete 7-column rows.
    readonly property var _calDays: {
        var firstDow = new Date(_year, _month, 1).getDay()  // 0=Sun
        var offset   = (firstDow + 6) % 7                   // 0=Mon...6=Sun
        var total    = new Date(_year, _month + 1, 0).getDate()
        var arr      = []
        for (var i = 0; i < offset; i++) arr.push(0)
        for (var d = 1; d <= total; d++) arr.push(d)
        while (arr.length % 7 !== 0) arr.push(0)
        return arr
    }

    Timer {
        interval: 60000
        running:  true
        repeat:   true
        onTriggered: root._today = new Date()
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    Column {
        anchors {
            top:    parent.top
            left:   parent.left
            right:  parent.right
            bottom: parent.bottom
            margins: 8
        }
        spacing: 8

        // ── Time ─────────────────────────────────────────────────────────────
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth:  _timeText.implicitWidth + _secsText.implicitWidth
            implicitHeight: _timeText.implicitHeight

            Text {
                id: _timeText
                anchors.left:           parent.left
                anchors.verticalCenter: parent.verticalCenter
                text:           Qt.formatTime(new Date(0, 0, 0, DateTime.hours, DateTime.minutes), "HH:mm")
                color:          Theme.widget.textColor
                font.family:    Theme.widget.fontFamily
                font.pixelSize: 30
                font.bold:      true
            }
            Text {
                id: _secsText
                anchors.left:   _timeText.right
                anchors.bottom: _timeText.bottom
                text:           ":" + String(DateTime.seconds).padStart(2, "0")
                color:          Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: 17
            }
        }

        // ── Month / year header ───────────────────────────────────────────────
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           Qt.formatDate(new Date(_year, _month, 1), "MMMM yyyy")
            color:          Theme.widget.textColor
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            font.bold:      true
        }

        // ── Day-of-week headers ───────────────────────────────────────────────
        Grid {
            id: _headerGrid
            width:         parent.width
            columns:       7
            columnSpacing: 4

            readonly property real cellW: (width - columnSpacing * (columns - 1)) / columns

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                Text {
                    required property var modelData
                    width:              _headerGrid.cellW
                    text:               modelData
                    color:              Theme.widget.textColorDim
                    font.family:        Theme.widget.fontFamily
                    font.pixelSize:     Theme.widget.fontSizeSmall
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // ── Calendar grid ─────────────────────────────────────────────────────
        Grid {
            id: _calGrid
            width:         parent.width
            columns:       7
            columnSpacing: 4
            rowSpacing:    2

            readonly property real cellW: (width - columnSpacing * (columns - 1)) / columns

            Repeater {
                model: root._calDays
                delegate: Item {
                    required property int index
                    required property var modelData   // 0 = empty, 1-31 = day

                    width:  _calGrid.cellW
                    height: Math.round(_calGrid.cellW * 0.7)

                    // Today highlight circle
                    Rectangle {
                        visible:         modelData > 0 && modelData === root._day
                        width:           Math.min(parent.width, parent.height) - 2
                        height:          width
                        radius:          width / 2
                        anchors.centerIn: parent
                        color:           Theme.colors.primary
                        opacity:         0.20
                    }

                    Text {
                        anchors.centerIn:    parent
                        visible:             modelData > 0
                        text:                modelData > 0 ? modelData.toString() : ""
                        color:               modelData === root._day
                                             ? Theme.colors.primary
                                             : Theme.widget.textColor
                        font.family:         Theme.widget.fontFamily
                        font.pixelSize:      Theme.widget.fontSizeSmall
                        font.bold:           modelData === root._day
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
