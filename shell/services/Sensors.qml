pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// The host's hardware sensors, from the unit sensors of the shell's application: its stream sensors.readings,
// every sensor whole at every reading; its question sensors.snapshot for the present and for where the
// sensors come from; its question sensors.history for one sensor's recent values; and its occurrences —
// thresholds held, alarms, trip points — as the standing subscription carries them. Nothing here reads /sys.
//
// It joins the present to what follows without a gap, through StreamJoin; on every attachment it joins again.
//
// The level of a sensor is the Plugin's — its own limits or the application's, with its hysteresis — so the
// shell colours what the Plugin says and decides no threshold of its own.
//
// ── Properties ────────────────────────────────────────────────────────────────
//   sensors        — every sensor of the latest reading, as the Plugin states it:
//                    { id, source, device, kind, label, unit, value, high, critical, level, alarm, error }
//   temperatures   — the temperatures read, hottest first
//   cpu            — the CPU's temperature where a CPU chip is found, else the hottest; null when none
//   cpuCelsius     — cpu's value, rounded; -1 when none
//   hottest        — the hottest temperature; null when none
//   level          — the worst level among the sensors: "normal" | "high" | "critical"
//   present        — at least one temperature is read
//   sequence, atMs — the latest reading's count and time
//   truncated      — the reading held more sensors than one payload carries
//   intervalMs, sources, signals, note — what the snapshot last said of the reading itself
//   events         — the unit's occurrences since the shell attached, newest first (at most 30):
//                    { seq, time, occurrence, severity, line, detail }
//   selected, series — the sensor whose history is followed, and its points [{ at_ms, value }]
Singleton {
    id: root

    readonly property string unit: "sensors"

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    readonly property bool ready: _reading !== null
    readonly property bool loading: !ready && error === ""
    readonly property string error: join.error

    // Derived from the attachment and the unit — nothing to start.
    function initialize(): void {}

    // ── The reading ───────────────────────────────────────────────────────────
    readonly property var sensors: _reading && _reading.sensors ? _reading.sensors : []
    readonly property int sequence: _reading ? _reading.sequence : 0
    readonly property real atMs: _reading ? _reading.at_ms : 0
    readonly property bool truncated: _reading ? !!_reading.truncated : false

    readonly property var temperatures: sensors
        .filter(s => s.kind === "temperature" && s.value !== null && s.value !== undefined)
        .sort((a, b) => b.value - a.value)

    readonly property bool present: temperatures.length > 0
    readonly property var hottest: present ? temperatures[0] : null

    // The chips and thermal zones that are the CPU's, as the kernel names them.
    readonly property var _cpuDevices: ["k10temp", "zenpower", "coretemp", "cpu_thermal", "x86_pkg_temp", "soc_thermal"]
    readonly property var cpu: {
        const own = temperatures.filter(t => _cpuDevices.indexOf(t.device) >= 0);
        return own.length > 0 ? own[0] : hottest;
    }
    readonly property int cpuCelsius: cpu ? Math.round(cpu.value) : -1

    readonly property string level: {
        let worst = "normal";
        for (const s of sensors) {
            if (s.level === "critical")
                return "critical";
            if (s.level === "high")
                worst = "high";
        }
        return worst;
    }

    // ── What the snapshot says of the reading ─────────────────────────────────
    property int intervalMs: 0
    property var sources: ({})
    property var signals: null
    property string note: ""

    // Asks the snapshot again, for what only it states: where the sensors come from and what is followed.
    function refresh(): void {
        if (!Yoke.attached)
            return;
        Yoke.link.ask(unit, "sensors.snapshot", "{}", answer => {
            const v = Yoke.json(answer);
            if (v)
                _describe(v);
        }, refusal => console.warn("sensors: sensors.snapshot refused: " + refusal.code));
    }

    function _describe(v: var): void {
        if (v.interval_ms !== undefined)
            intervalMs = v.interval_ms;
        if (v.sources !== undefined)
            sources = v.sources;
        if (v.signals !== undefined)
            signals = v.signals;
        note = v.note || "";
    }

    // ── One sensor's history ──────────────────────────────────────────────────
    property string selected: ""
    property var series: []
    // As many points as the history is asked for, and kept as readings arrive.
    readonly property int seriesLength: 90

    function select(id: string): void {
        selected = selected === id ? "" : id;
        series = [];
        if (selected === "" || !Yoke.attached)
            return;
        const asked = selected;
        Yoke.link.ask(unit, "sensors.history", JSON.stringify({ id: asked, n: seriesLength }), answer => {
            const v = Yoke.json(answer);
            if (v && root.selected === asked)
                root.series = v.points || [];
        }, refusal => console.warn("sensors: sensors.history refused: " + refusal.code));
    }

    function _follow(reading: var): void {
        if (selected === "" || !reading.sensors)
            return;
        const s = reading.sensors.find(x => x.id === selected);
        if (!s || s.value === null || s.value === undefined)
            return;
        const last = series.length > 0 ? series[series.length - 1] : null;
        if (last && last.at_ms >= reading.at_ms)
            return;
        const next = series.concat([{ at_ms: reading.at_ms, value: s.value }]);
        series = next.length > seriesLength ? next.slice(next.length - seriesLength) : next;
    }

    // ── Occurrences ───────────────────────────────────────────────────────────
    property var events: []
    readonly property int _eventsKept: 30

    function _occurred(e: var): void {
        if (e.type !== "unit.occurrence.reported" || !e.subject || e.subject.identity !== unit)
            return;
        const detail = e.detail ? Yoke.json(e.detail) : null;
        const entry = {
            seq: e.seq,
            time: e.time,
            occurrence: e.occurrence,
            severity: e.severity || 0,
            line: (e.line || (detail && detail.line) || e.occurrence),
            detail: detail
        };
        const next = [entry].concat(events);
        events = next.length > _eventsKept ? next.slice(0, _eventsKept) : next;
    }

    property var _reading: null

    Connections {
        target: Yoke.link
        function onReceived(event: var): void {
            root._occurred(event);
        }
    }

    StreamJoin {
        id: join

        unit: root.unit
        stream: "sensors.readings"
        question: "sensors.snapshot"
        onValue: v => {
            root._describe(v);
            root._reading = v;
            root._follow(v);
        }
    }
}
