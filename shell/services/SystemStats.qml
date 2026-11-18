pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Yoke.Interface

// CPU and memory, from the unit hw-monitor of the shell's application: its streams hw.cpu and hw.memory,
// one reading a second by default, and its question hw.snapshot for the present. Nothing here reads /proc.
//
// It joins the present to what follows without a gap: it opens both deliveries, starts both streams, and
// only then asks the snapshot; frames arriving meanwhile are held, and those at or below the sequence the
// snapshot states for their stream are dropped. On every attachment, the first or one after the Core came
// back, it joins again.
//
// The properties are my-qshell's, so its widgets bind unchanged:
//   cpuTotal, cpuCores, coreCount                                   [0–100]
//   ramUsedPercent, swapUsedPercent                                 [0–100]
//   ramTotalMiB, ramUsedMiB, ramFreeMiB, ramAvailableMiB,
//   ramCachedMiB (Cached + Buffers, as my-qshell counted it), ramBuffersMiB,
//   swapTotalMiB, swapUsedMiB, swapFreeMiB                          MiB
//   ready                                                           both figures arrived at least once
Singleton {
    id: root

    readonly property string unit: "hw-monitor"

    property int cpuTotal: 0
    property var cpuCores: []
    property int coreCount: 0

    property int ramUsedPercent: 0
    property int swapUsedPercent: 0
    property int ramTotalMiB: 0
    property int ramUsedMiB: 0
    property int ramFreeMiB: 0
    property int ramAvailableMiB: 0
    property int ramCachedMiB: 0
    property int ramBuffersMiB: 0
    property int swapTotalMiB: 0
    property int swapUsedMiB: 0
    property int swapFreeMiB: 0

    readonly property bool ready: _cpuSeen && _memorySeen

    property bool _cpuSeen: false
    property bool _memorySeen: false
    // Per stream: frames held until the snapshot answers (null once joined), and the last sequence applied.
    property var _held: ({ "hw.cpu": [], "hw.memory": [] })
    property var _applied: ({})
    property bool _joining: false

    function _join(): void {
        if (_joining || !Yoke.attached || !cpu.open || !memory.open)
            return;
        _joining = true;
        _held = { "hw.cpu": [], "hw.memory": [] };
        _applied = {};
        for (const stream of ["hw.cpu", "hw.memory"])
            Yoke.link.startStream(unit, stream, null,
                                  refusal => console.warn("stats: " + stream + " not started: " + refusal.code));
        Yoke.link.ask(unit, "hw.snapshot", "", answer => {
            const present = Yoke.json(answer);
            for (const stream of ["hw.cpu", "hw.memory"]) {
                const value = present ? present[stream === "hw.cpu" ? "cpu" : "memory"] : null;
                const at = value && value.sequence !== undefined ? value.sequence : 0;
                if (value)
                    _show(stream, value);
                _applied[stream] = at;
                const kept = _held[stream].filter(v => v.sequence > at);
                _held[stream] = null;
                for (const v of kept)
                    _apply(stream, v);
            }
        }, refusal => {
            console.warn("stats: hw.snapshot refused: " + refusal.code);
            _joining = false;
        });
    }

    function _arrived(stream: string, frame: var): void {
        const value = Yoke.json(frame.payload);
        if (!value)
            return;
        if (_held[stream] !== null)
            _held[stream].push(value);
        else
            _apply(stream, value);
    }

    function _apply(stream: string, value: var): void {
        const last = _applied[stream];
        if (last !== undefined && value.sequence <= last)
            return;
        _applied[stream] = value.sequence;
        _show(stream, value);
    }

    function _show(stream: string, v: var): void {
        const mib = bytes => Math.round(bytes / 1048576);
        if (stream === "hw.cpu") {
            cpuTotal = Math.round(v.aggregate_usage_percent);
            const cores = v.cores.slice().sort((a, b) => a.core_index - b.core_index).map(c => Math.round(c.usage_percent));
            cpuCores = cores;
            coreCount = cores.length;
            _cpuSeen = true;
        } else {
            ramTotalMiB = mib(v.total_bytes);
            ramUsedMiB = mib(v.used_bytes);
            ramFreeMiB = mib(v.free_bytes);
            ramAvailableMiB = mib(v.available_bytes);
            ramBuffersMiB = mib(v.buffers_bytes);
            ramCachedMiB = mib(v.cached_bytes + v.buffers_bytes);
            ramUsedPercent = Math.round(v.usage_percent);
            swapTotalMiB = mib(v.swap_total_bytes);
            swapUsedMiB = mib(v.swap_used_bytes);
            swapFreeMiB = mib(v.swap_free_bytes);
            swapUsedPercent = v.swap_total_bytes > 0 ? Math.round(v.swap_used_bytes / v.swap_total_bytes * 100) : 0;
            _memorySeen = true;
        }
    }

    Connections {
        target: Yoke
        function onAttachedChanged(): void {
            root._joining = false;
            root._join();
        }
    }

    Delivery {
        id: cpu

        attachment: Yoke.link
        unit: root.unit
        stream: "hw.cpu"
        onOpenChanged: root._join()
        onFrame: frame => root._arrived("hw.cpu", frame)
    }

    Delivery {
        id: memory

        attachment: Yoke.link
        unit: root.unit
        stream: "hw.memory"
        onOpenChanged: root._join()
        onFrame: frame => root._arrived("hw.memory", frame)
    }
}
