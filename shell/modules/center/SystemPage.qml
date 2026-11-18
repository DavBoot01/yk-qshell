pragma ComponentBehavior: Bound

import QtQuick
import qs.themes
import qs.services

// SystemPage — CPU and RAM detail view.
//
// CPU: total percentage, per-core mini bars.
// RAM: used/total percentage + GiB detail. Swap shown when present.
// Colors adapt to load: warn (>70%) and critical (>90%) thresholds.
Item {
    id: root

    // Returns the threshold color for a given percentage.
    function _loadColor(pct) {
        if (pct >= 90) return Theme.widget.colorCritical
        if (pct >= 70) return Theme.widget.colorWarn
        return Theme.colors.primary
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    Column {
        anchors {
            top:    parent.top
            left:   parent.left
            right:  parent.right
            bottom: parent.bottom
            margins: 12
        }
        spacing: 10

        // ── CPU section ───────────────────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 6

            // Label + total percentage
            Row {
                width:  parent.width

                Text {
                    text:           Translation.tr("CPU")
                    color:          Theme.widget.textColorDim
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSizeSmall
                    font.bold:      true
                    width:          parent.width / 2
                }

                Text {
                    text:               SystemStats.cpuTotal + " %"
                    color:              root._loadColor(SystemStats.cpuTotal)
                    font.family:        Theme.widget.fontFamily
                    font.pixelSize:     Theme.widget.fontSize
                    font.bold:          true
                    width:              parent.width / 2
                    horizontalAlignment: Text.AlignRight

                    Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
                }
            }

            // Total usage bar
            Rectangle {
                width:  parent.width
                height: 6
                radius: 3
                color:  Theme.colors.outline

                Rectangle {
                    width:   Math.max(radius * 2, parent.width * (SystemStats.cpuTotal / 100))
                    height:  parent.height
                    radius:  parent.radius
                    color:   root._loadColor(SystemStats.cpuTotal)

                    Behavior on width { NumberAnimation { duration: Theme.animation.duration } }
                    Behavior on color { ColorAnimation  { duration: Theme.animation.duration } }
                }
            }

            // Per-core mini bars
            Row {
                width:   parent.width
                height:  28
                spacing: 2

                Repeater {
                    model: SystemStats.cpuCores
                    delegate: Item {
                        required property var modelData  // core % [0-100]
                        required property int index

                        width:  (parent.width - (SystemStats.coreCount - 1) * 2) / Math.max(1, SystemStats.coreCount)
                        height: parent.height

                        // Background track
                        Rectangle {
                            anchors.bottom:       parent.bottom
                            width:                parent.width
                            height:               parent.height
                            radius:               2
                            color:                Theme.colors.outline
                            opacity:              0.4
                        }

                        // Fill bar
                        Rectangle {
                            anchors.bottom:       parent.bottom
                            width:                parent.width
                            height:               Math.max(4, parent.height * (modelData / 100))
                            radius:               2
                            color:                root._loadColor(modelData)

                            Behavior on height { NumberAnimation { duration: Theme.animation.duration } }
                            Behavior on color  { ColorAnimation  { duration: Theme.animation.duration } }
                        }
                    }
                }
            }
        }

        // ── Separator ─────────────────────────────────────────────────────────
        Rectangle {
            width:  parent.width
            height: 1
            color:  Theme.colors.outline
            opacity: 0.5
        }

        // ── RAM section ───────────────────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 6

            // Label + percentage
            Row {
                width: parent.width

                Text {
                    text:           Translation.tr("RAM")
                    color:          Theme.widget.textColorDim
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSizeSmall
                    font.bold:      true
                    width:          parent.width / 2
                }

                Text {
                    text:               SystemStats.ramUsedPercent + " %"
                    color:              root._loadColor(SystemStats.ramUsedPercent)
                    font.family:        Theme.widget.fontFamily
                    font.pixelSize:     Theme.widget.fontSize
                    font.bold:          true
                    width:              parent.width / 2
                    horizontalAlignment: Text.AlignRight

                    Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
                }
            }

            // Usage bar
            Rectangle {
                width:  parent.width
                height: 6
                radius: 3
                color:  Theme.colors.outline

                Rectangle {
                    width:   Math.max(radius * 2, parent.width * (SystemStats.ramUsedPercent / 100))
                    height:  parent.height
                    radius:  parent.radius
                    color:   root._loadColor(SystemStats.ramUsedPercent)

                    Behavior on width { NumberAnimation { duration: Theme.animation.duration } }
                    Behavior on color { ColorAnimation  { duration: Theme.animation.duration } }
                }
            }

            // Used / Total detail
            Text {
                readonly property real usedGiB:  SystemStats.ramUsedMiB / 1024
                readonly property real totalGiB: SystemStats.ramTotalMiB / 1024

                text: usedGiB.toFixed(1) + " GiB  /  " + totalGiB.toFixed(1) + " GiB"
                color:          Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall
            }
        }

        // ── Swap (only when swap is present) ──────────────────────────────────
        Column {
            width:   parent.width
            spacing: 6
            visible: SystemStats.swapTotalMiB > 0

            Rectangle {
                width:  parent.width
                height: 1
                color:  Theme.colors.outline
                opacity: 0.5
            }

            Row {
                width: parent.width

                Text {
                    text:           Translation.tr("Swap")
                    color:          Theme.widget.textColorDim
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSizeSmall
                    font.bold:      true
                    width:          parent.width / 2
                }

                Text {
                    text:               SystemStats.swapUsedPercent + " %"
                    color:              root._loadColor(SystemStats.swapUsedPercent)
                    font.family:        Theme.widget.fontFamily
                    font.pixelSize:     Theme.widget.fontSize
                    font.bold:          true
                    width:              parent.width / 2
                    horizontalAlignment: Text.AlignRight
                }
            }

            Rectangle {
                width:  parent.width
                height: 6
                radius: 3
                color:  Theme.colors.outline

                Rectangle {
                    width:  Math.max(radius * 2, parent.width * (SystemStats.swapUsedPercent / 100))
                    height: parent.height
                    radius: parent.radius
                    color:  root._loadColor(SystemStats.swapUsedPercent)

                    Behavior on width { NumberAnimation { duration: Theme.animation.duration } }
                }
            }
        }
    }
}
