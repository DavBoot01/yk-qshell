pragma ComponentBehavior: Bound

import QtQuick
import qs.themes
import qs.services
import qs.widgets

// SensorsPage — everything the unit sensors states, in one scrolling page.
//
//   • Header: how many sensors, where they come from, how often they are read.
//   • History: the selected sensor's recent values, with its limits. A gauge or a row selects it.
//   • Temperatures: a ring each, filled to the value's share of its limit — critical, else high, else 100 °C.
//   • Fan duty, cooling and humidity: a ring each, on their percentage.
//   • Every other reading — fans, voltages, currents, power, energy, frequency, pressure, light — as rows.
//   • Events: the thresholds held, the alarms and the trip points since the shell attached.
//   • What the Plugin follows: the alarm attributes waited on and the kernel's thermal events.
//
// Colours are the Plugin's levels: normal, high, critical. The shell decides no threshold of its own.
Item {
    id: root

    Component.onCompleted: Sensors.refresh()

    function _levelColor(level) {
        if (level === "critical") return Theme.widget.colorCritical
        if (level === "high")     return Theme.widget.colorWarn
        return Theme.colors.primary
    }

    function _severityColor(severity) {
        if (severity >= 70) return Theme.widget.colorCritical
        if (severity >= 50) return Theme.widget.colorWarn
        if (severity >= 30) return Theme.colors.primary
        return Theme.widget.textColorDim
    }

    function _name(s) {
        return s.label && s.label !== "" ? s.device + " " + s.label : s.device
    }

    function _format(value, unit) {
        if (value === null || value === undefined) return "—"
        switch (unit) {
        case "°C":  return value.toFixed(1) + " °C"
        case "V":   return value.toFixed(3) + " V"
        case "A":   return value.toFixed(2) + " A"
        case "W":   return value.toFixed(1) + " W"
        case "J":   return value >= 1e6 ? (value / 3.6e6).toFixed(2) + " kWh" : value.toFixed(0) + " J"
        case "kPa": return value.toFixed(1) + " kPa"
        default:    return Math.round(value) + " " + unit
        }
    }

    // The sensors in a ring, and the rest.
    readonly property var _ringKinds: ["pwm", "cooling", "humidity"]
    // Sensors of one kind on one device — a processor's sixteen cooling devices — share one ring, at the
    // highest of their values, and say how many they are.
    readonly property var _rings: {
        const groups = []
        const at = {}
        for (const s of Sensors.sensors) {
            if (_ringKinds.indexOf(s.kind) < 0) continue
            const key = s.kind + "/" + s.device
            if (at[key] === undefined) { at[key] = groups.length; groups.push([]) }
            groups[at[key]].push(s)
        }
        return groups.map(g => {
            if (g.length === 1) return Object.assign({ count: 1 }, g[0])
            const read = g.filter(s => s.value !== null && s.value !== undefined)
            const top = read.length > 0 ? read.reduce((a, b) => b.value > a.value ? b : a) : g[0]
            const worst = g.some(s => s.level === "critical") ? "critical" : g.some(s => s.level === "high") ? "high" : top.level
            return Object.assign({}, top, { count: g.length, label: "", level: worst })
        })
    }
    readonly property var _rows: Sensors.sensors.filter(s => s.kind !== "temperature" && _ringKinds.indexOf(s.kind) < 0)
    readonly property var _selectedSensor: Sensors.sensors.find(s => s.id === Sensors.selected) || null

    // ── Section heading ───────────────────────────────────────────────────────
    component Heading: Text {
        color:          Theme.widget.textColorDim
        font.family:    Theme.widget.fontFamily
        font.pixelSize: Theme.widget.fontSizeSmall
        font.bold:      true
        topPadding:     4
    }

    component Separator: Rectangle {
        height:  1
        color:   Theme.colors.outline
        opacity: 0.5
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 12
        contentWidth:  width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: content
            width: flick.width
            spacing: 8

            // ── Header ────────────────────────────────────────────────────────
            Row {
                width: parent.width

                Text {
                    width:          parent.width * 0.5
                    text:           Translation.tr("Sensors")
                    color:          Theme.widget.textColor
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSize
                    font.bold:      true
                }

                Text {
                    width:               parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                    color:               Theme.widget.textColorDim
                    font.family:         Theme.widget.fontFamily
                    font.pixelSize:      Theme.widget.fontSizeSmall
                    text: Sensors.intervalMs > 0 ? Sensors.sensors.length + " " + Translation.tr("sensors") + " · " + Translation.tr("every") + " "
                                                   + (Sensors.intervalMs / 1000) + " s" : ""
                }
            }

            // Where the sensors come from
            Text {
                width:          parent.width
                visible:        text !== ""
                wrapMode:       Text.Wrap
                color:          Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall - 1
                text: {
                    const src = Sensors.sources || {}
                    return Object.keys(src).filter(k => src[k] > 0).map(k => k + " " + src[k]).join(" · ")
                }
            }

            Text {
                width:          parent.width
                visible:        text !== ""
                wrapMode:       Text.Wrap
                color:          Sensors.error !== "" ? Theme.widget.colorCritical : Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall
                text: Sensors.error !== "" ? Sensors.error
                    : Sensors.loading ? Translation.tr("Waiting for the first reading…")
                    : Sensors.truncated ? Translation.tr("More sensors than one reading carries: some are left out")
                    : Sensors.note
            }

            // ── History of the selected sensor ────────────────────────────────
            Column {
                width:   parent.width
                spacing: 4
                visible: root._selectedSensor !== null

                Row {
                    width: parent.width

                    Text {
                        width:          parent.width * 0.6
                        elide:          Text.ElideRight
                        text:           root._selectedSensor ? root._name(root._selectedSensor) : ""
                        color:          Theme.widget.textColor
                        font.family:    Theme.widget.fontFamily
                        font.pixelSize: Theme.widget.fontSizeSmall
                        font.bold:      true
                    }

                    Text {
                        width:               parent.width * 0.4
                        horizontalAlignment: Text.AlignRight
                        color:               Theme.widget.textColorDim
                        font.family:         Theme.widget.fontFamily
                        font.pixelSize:      Theme.widget.fontSizeSmall
                        text: {
                            const pts = Sensors.series
                            const s = root._selectedSensor
                            if (!s || pts.length === 0) return ""
                            const vs = pts.map(p => p.value)
                            return "min " + root._format(Math.min(...vs), s.unit) + "  max " + root._format(Math.max(...vs), s.unit)
                        }
                    }
                }

                Canvas {
                    id: chart
                    width:  parent.width
                    height: 56

                    readonly property var points: Sensors.series
                    readonly property var sensor: root._selectedSensor
                    onPointsChanged: requestPaint()
                    onSensorChanged: requestPaint()
                    onWidthChanged:  requestPaint()

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        const pts = points
                        if (!sensor || pts.length < 2) return
                        const vs = pts.map(p => p.value)
                        let lo = Math.min(...vs), hi = Math.max(...vs)
                        const limits = [sensor.high, sensor.critical].filter(l => l !== null && l !== undefined)
                        // A limit is drawn only where it is near enough the values to say something.
                        const near = limits.filter(l => l <= hi + (hi - lo + 1) * 1.5)
                        for (const l of near) { lo = Math.min(lo, l); hi = Math.max(hi, l) }
                        if (hi - lo < 1) { hi += 0.5; lo -= 0.5 }
                        const pad = 3
                        const t0 = pts[0].at_ms, t1 = pts[pts.length - 1].at_ms
                        const x = t => pad + (width - 2 * pad) * (t1 > t0 ? (t - t0) / (t1 - t0) : 1)
                        const y = v => height - pad - (height - 2 * pad) * (v - lo) / (hi - lo)

                        ctx.lineWidth = 1
                        ctx.setLineDash([3, 3])
                        for (const l of near) {
                            ctx.strokeStyle = l === sensor.critical ? Theme.widget.colorCritical : Theme.widget.colorWarn
                            ctx.beginPath(); ctx.moveTo(pad, y(l)); ctx.lineTo(width - pad, y(l)); ctx.stroke()
                        }
                        ctx.setLineDash([])

                        const line = root._levelColor(sensor.level)
                        ctx.beginPath()
                        ctx.moveTo(x(pts[0].at_ms), y(pts[0].value))
                        for (let i = 1; i < pts.length; i++)
                            ctx.lineTo(x(pts[i].at_ms), y(pts[i].value))
                        ctx.strokeStyle = line
                        ctx.lineWidth = 1.5
                        ctx.stroke()

                        ctx.lineTo(x(t1), height - pad)
                        ctx.lineTo(x(t0), height - pad)
                        ctx.closePath()
                        ctx.fillStyle = Qt.rgba(line.r, line.g, line.b, 0.15)
                        ctx.fill()
                    }
                }

                Separator { width: parent.width }
            }

            // ── Temperatures ──────────────────────────────────────────────────
            Heading {
                visible: Sensors.temperatures.length > 0
                text:    Translation.tr("Temperatures")
            }

            Flow {
                width:   parent.width
                spacing: 8
                visible: Sensors.temperatures.length > 0

                Repeater {
                    model: Sensors.temperatures
                    delegate: CircularGauge {
                        required property var modelData
                        width: (content.width - 4 * 8) / 5
                        readonly property real _limit: modelData.critical || modelData.high || 100

                        fraction: modelData.value / _limit
                        color:    root._levelColor(modelData.level)
                        value:    Math.round(modelData.value) + "°"
                        label:    modelData.label || modelData.device
                        sublabel: Array.isArray(modelData.alarm) && modelData.alarm.length > 0 ? "⚠ " + modelData.alarm.join(", ")
                                : modelData.device + (modelData.critical ? " · " + Math.round(modelData.critical) + "°"
                                                    : modelData.high ? " · " + Math.round(modelData.high) + "°" : "")
                        selected: Sensors.selected === modelData.id
                        onClicked: Sensors.select(modelData.id)
                    }
                }
            }

            // ── Fan duty, cooling, humidity ───────────────────────────────────
            Heading {
                visible: root._rings.length > 0
                text:    Translation.tr("Duty, cooling and humidity")
            }

            Flow {
                width:   parent.width
                spacing: 8
                visible: root._rings.length > 0

                Repeater {
                    model: root._rings
                    delegate: CircularGauge {
                        required property var modelData
                        width: (content.width - 4 * 8) / 5

                        fraction: (modelData.value || 0) / 100
                        color:    modelData.error ? Theme.widget.textColorDim : root._levelColor(modelData.level)
                        value:    modelData.value === null || modelData.value === undefined ? "—" : Math.round(modelData.value) + "%"
                        label:    modelData.count > 1 ? modelData.device : root._name(modelData)
                        sublabel: (modelData.count > 1 ? modelData.count + " × " : "") + Translation.tr(modelData.kind)
                        selected: Sensors.selected === modelData.id
                        onClicked: Sensors.select(modelData.id)
                    }
                }
            }

            // ── Other readings ────────────────────────────────────────────────
            Heading {
                visible: root._rows.length > 0
                text:    Translation.tr("Other readings")
            }

            Column {
                width:   parent.width
                spacing: 1
                visible: root._rows.length > 0

                Repeater {
                    model: root._rows
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        // The alarm attributes the kernel raised for this sensor.
                        readonly property bool _alarm: Array.isArray(modelData.alarm) && modelData.alarm.length > 0

                        width:  parent.width
                        height: 22
                        radius: 4
                        color:  Sensors.selected === modelData.id ? Theme.widget.activeBackground
                              : rowMouse.containsMouse ? Theme.widget.hoverBackground : "transparent"

                        Text {
                            id: kindText
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            width:          84
                            elide:          Text.ElideRight
                            text:           Translation.tr(row.modelData.kind)
                            color:          Theme.widget.textColorDim
                            font.family:    Theme.widget.fontFamily
                            font.pixelSize: Theme.widget.fontSizeSmall - 1
                        }

                        Text {
                            anchors.left: kindText.right
                            anchors.right: valueText.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            elide:          Text.ElideRight
                            text:           (row._alarm ? "⚠ " : "") + root._name(row.modelData)
                            color:          row._alarm ? Theme.widget.colorCritical : Theme.widget.textColor
                            font.family:    Theme.widget.fontFamily
                            font.pixelSize: Theme.widget.fontSizeSmall
                        }

                        Text {
                            id: valueText
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            text:           row.modelData.error ? Translation.tr("unreadable") : root._format(row.modelData.value, row.modelData.unit)
                            color:          row.modelData.error ? Theme.widget.textColorDim
                                          : row.modelData.level ? root._levelColor(row.modelData.level) : Theme.widget.textColor
                            font.family:    Theme.widget.fontFamily
                            font.pixelSize: Theme.widget.fontSizeSmall
                            font.bold:      true
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    Sensors.select(row.modelData.id)
                        }
                    }
                }
            }

            // ── Events ────────────────────────────────────────────────────────
            Separator { width: parent.width }

            Heading { text: Translation.tr("Events") }

            Text {
                visible:        Sensors.events.length === 0
                width:          parent.width
                wrapMode:       Text.Wrap
                text:           Translation.tr("No threshold, alarm or trip point since the shell attached")
                color:          Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall
            }

            Column {
                width:   parent.width
                spacing: 2

                Repeater {
                    model: Sensors.events
                    delegate: Row {
                        id: ev
                        required property var modelData
                        width:   parent.width
                        spacing: 6

                        Rectangle {
                            width: 6; height: 6; radius: 3
                            anchors.verticalCenter: parent.verticalCenter
                            color: root._severityColor(ev.modelData.severity)
                        }

                        Text {
                            id: evTime
                            text:           ev.modelData.time ? Qt.formatTime(ev.modelData.time, "HH:mm:ss") : ""
                            color:          Theme.widget.textColorDim
                            font.family:    Theme.widget.fontFamily
                            font.pixelSize: Theme.widget.fontSizeSmall - 1
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            width:          ev.width - 12 - evTime.width - 2 * ev.spacing
                            elide:          Text.ElideRight
                            text:           ev.modelData.line
                            color:          Theme.widget.textColor
                            font.family:    Theme.widget.fontFamily
                            font.pixelSize: Theme.widget.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // ── What the Plugin follows ───────────────────────────────────────
            Text {
                width:          parent.width
                visible:        Sensors.signals !== null
                wrapMode:       Text.Wrap
                topPadding:     4
                color:          Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall - 1
                text: Sensors.signals === null ? "" :
                    Translation.tr("Alarm attributes waited on") + ": " + Sensors.signals.alarm_attributes
                    + " · " + Translation.tr("thermal events") + ": "
                    + (Sensors.signals.thermal_events ? Translation.tr("followed") : Translation.tr("not followed"))
            }
        }
    }
}
