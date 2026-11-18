pragma ComponentBehavior: Bound

import QtQuick

import qs.themes

// Battery charge indicator — hidden when no battery is present (desktop/VM).
//
// ── Visual layout ─────────────────────────────────────────────────────────────
//   Line 1: level icon  +  percentage  (color-coded by level)
//   Line 2: power draw (W)  +  time remaining / until full
//
// ── Icon glyphs (Nerd Font MDI battery set) ───────────────────────────────────
//   Discharging: 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹  (10% steps)
//   Charging:    󰢜 󰂆 󰂇 󰂈 󰢝 󰂉 󰢞 󰂊 󰂋 󰂅  (10% steps)
//   Full / not charging at 100%: 󰁹
//   Unknown / no power data:     󰂑
Item {
    id: root

    // Presentational: bind from root.* in the parent.
    property bool   present:     false
    property int    percent:     0
    property bool   charging:    false
    property bool   full:        false
    property real   powerNow:    0.0
    property int    timeToFull:  -1
    property int    timeToEmpty: -1

    // Collapse completely when no battery detected
    visible: root.present
    implicitWidth:  visible ? col.implicitWidth  : 0
    implicitHeight: visible ? col.implicitHeight : 0

    // ── Icon helper ───────────────────────────────────────────────────────────
    readonly property string _icon: {
        if (root.full || (root.percent >= 100 && !root.charging))
            return "󰁹"
        const step = Math.min(Math.floor(root.percent / 10), 9)
        if (root.charging) {
            return ["󰢜","󰂆","󰂇","󰂈","󰢝","󰂉","󰢞","󰂊","󰂋","󰂅"][step]
        }
        return ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"][step]
    }

    // ── Color helper ──────────────────────────────────────────────────────────
    readonly property color _color: root.charging || root.full
        ? Theme.widget.textColor
        : root.percent <= 10
            ? Theme.widget.colorCritical
            : root.percent <= 20
                ? Theme.widget.colorWarn
                : Theme.widget.textColor

    // ── Time-remaining string ─────────────────────────────────────────────────
    readonly property string _timeStr: {
        const mins = root.charging ? root.timeToFull : root.timeToEmpty
        if (mins < 0) return "plugged in"
        if (mins < 60) return mins + "m"
        return Math.floor(mins / 60) + "h " + (mins % 60) + "m"
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    Column {
        id: col
        anchors.centerIn: parent
        spacing: 1

        // Line 1: icon + percentage
        Row {
            spacing: 3
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: root._icon
                color: root._color
                font.family: Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSize

                Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
            }

            Text {
                text: root.percent + "%"
                color: root._color
                font.family: Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSize

                Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
            }
        }

        // Line 2: power + time
        Row {
            spacing: 4
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                visible: root.powerNow > 0
                text:    root.powerNow.toFixed(1) + "W"
                color:   Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall
            }

            Text {
                text:  root._timeStr
                color: Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall
            }
        }
    }
}
