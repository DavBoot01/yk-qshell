pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.themes
import qs.services

// AudioPanel — volume slider and mute toggle.
//
// Reads from and writes to AudioService (PipeWire). While no sink is available
// (AudioService.ready == false) the controls are dimmed and a notice is shown.
// Custom press-and-drag slider: no QtQuick.Controls dependency.
Item {
    id: root

    implicitWidth:  parent ? parent.width  : 0
    implicitHeight: parent ? parent.height : 0

    Text {
        visible: !AudioService.ready
        anchors { top: parent.top; left: parent.left; right: parent.right }
        horizontalAlignment: Text.AlignHCenter
        text:           Translation.tr("No audio device")
        color:          Theme.widget.colorWarn
        font.family:    Theme.widget.fontFamily
        font.pixelSize: Theme.widget.fontSize
    }

    Column {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors.topMargin: AudioService.ready ? 0 : 28
        spacing: 18
        enabled: AudioService.ready
        opacity: AudioService.ready ? 1.0 : 0.4

        // ── Volume row ────────────────────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 10

            // Label row: icon + "Volume" + percentage
            Row {
                width: parent.width
                spacing: 6

                Text {
                    text:           AudioService.muted ? "󰖁" : _volIcon
                    color:          AudioService.muted
                        ? Theme.widget.colorWarn
                        : Theme.widget.textColor
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSizeLarge
                    anchors.verticalCenter: parent.verticalCenter

                    readonly property string _volIcon:
                        AudioService.volume === 0 ? "󰕿" :
                        AudioService.volume < 50  ? "󰖀" :
                                                    "󰕾"

                    Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
                }

                Text {
                    text:           Translation.tr("Volume")
                    color:          Theme.widget.textColor
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSize
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { Layout.fillWidth: true; width: 1; height: 1 }

                Text {
                    text:           AudioService.volume + "%"
                    color:          AudioService.muted
                        ? Theme.widget.colorWarn
                        : Theme.widget.textColorDim
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSize
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
                }
            }

            // Drag slider track
            Item {
                id: sliderTrack
                width:  parent.width
                height: 6

                // Track background
                Rectangle {
                    anchors.fill: parent
                    radius:       height / 2
                    color:        Theme.colors.outline
                }

                // Fill up to current volume (capped visually at 100%)
                Rectangle {
                    width:  Math.min(AudioService.volume / 100, 1.0) * parent.width
                    height: parent.height
                    radius: height / 2
                    color:  AudioService.muted
                        ? Theme.widget.colorWarn
                        : Theme.colors.primary

                    Behavior on width { NumberAnimation { duration: 80 } }
                    Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
                }

                // Overdrive zone indicator (100–150%)
                Rectangle {
                    visible: AudioService.volume > 100
                    x:       parent.width * (100 / 150)
                    width:   1
                    height:  parent.height + 4
                    anchors.verticalCenter: parent.verticalCenter
                    color:   Theme.widget.colorWarn
                    opacity: 0.7
                }

                // Drag handle
                Rectangle {
                    x:      Math.min(AudioService.volume / 150, 1.0) * (parent.width - width)
                    y:      (parent.height - height) / 2
                    width:  14
                    height: 14
                    radius: 7
                    color:  AudioService.muted ? Theme.widget.colorWarn : Theme.colors.primary

                    Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
                }

                // Drag handler — maps x position [0, width] to volume [0, 150]
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape:  Qt.SizeHorCursor

                    function _setFromX(mx) {
                        var ratio = Math.max(0, Math.min(1, mx / sliderTrack.width))
                        AudioService.setVolume(Math.round(ratio * 150))
                    }

                    onPressed:      mouse => _setFromX(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed) _setFromX(mouse.x)
                    }
                }
            }
        }

        // ── Mute toggle button ────────────────────────────────────────────────
        Rectangle {
            width:  parent.width
            height: 38
            radius: Theme.rounding.button
            color:  AudioService.muted
                ? Qt.rgba(249 / 255, 226 / 255, 175 / 255, 0.15)
                : muteHover.containsMouse
                    ? Theme.widget.hoverBackground
                    : Theme.widget.subtleBackground

            Behavior on color { ColorAnimation { duration: Theme.animation.duration } }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text:           AudioService.muted ? "󰖁" : "󰕾"
                    color:          AudioService.muted
                        ? Theme.widget.colorWarn
                        : Theme.widget.textColorDim
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSize
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
                }

                Text {
                    text:           AudioService.muted ? "Unmute" : "Mute"
                    color:          AudioService.muted
                        ? Theme.widget.colorWarn
                        : Theme.widget.textColor
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSize
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
                }
            }

            MouseArea {
                id: muteHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked:    AudioService.toggleMute()
            }
        }
    }
}
