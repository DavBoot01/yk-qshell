pragma ComponentBehavior: Bound

import QtQuick

import qs.themes

// AudioWidget — compact audio indicator for the bar chip.
//
// The output's volume icon and percentage; beside them a headphones icon when
// the sound goes to headphones or a headset, and a microphone icon when there
// is an input (crossed out when it is muted). Whatever is muted takes the highlight colour, Theme.colors.primary.
// Presentational: values are bound by the parent.
//
// The wheel over it emits stepped(n): n notches, positive up. A touchpad's
// fine scrolling is gathered into whole notches.
//
// Bind to a BarChip and toggle the right panel via PanelManager
// (handled by the BarChip / Bar.qml, not here).
Item {
    id: root

    property int    volume:     0
    property bool   muted:      false
    // "headphones" | "headset" | "speaker" | "hdmi" | … | ""
    property string outputForm: ""
    property bool   hasInput:   false
    property bool   inputMuted: false

    signal stepped(int steps)

    readonly property bool _onHeadphones: root.outputForm === "headphones" || root.outputForm === "headset"

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight

    // One notch is 120 eighths of a degree; a touchpad sends less at a time.
    property real _wheel: 0
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            root._wheel += event.angleDelta.y
            const steps = Math.trunc(root._wheel / 120)
            if (steps !== 0) {
                root._wheel -= steps * 120
                root.stepped(steps)
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        // Volume icon
        Text {
            text:
                root.muted      ? "󰖁" :
                root.volume === 0 ? "󰕿" :
                root.volume < 50  ? "󰖀" :
                                            "󰕾"

            color: root.muted
                ? Theme.colors.primary
                : Theme.widget.textColor

            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
        }

        // Percentage
        Text {
            text:           root.volume + "%"
            color:          root.muted
                ? Theme.colors.primary
                : Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
        }

        // Headphones — the sound goes to headphones or a headset
        Text {
            visible:        root._onHeadphones
            text:           root.outputForm === "headset" ? "󰋎" : "󰋋"
            color:          root.muted ? Theme.colors.primary : Theme.widget.textColor
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }

        // Microphone — the default input, crossed out when muted
        Text {
            visible:        root.hasInput
            text:           root.inputMuted ? "󰍭" : "󰍬"
            color:          root.inputMuted ? Theme.colors.primary : Theme.widget.textColor
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
        }
    }
}
