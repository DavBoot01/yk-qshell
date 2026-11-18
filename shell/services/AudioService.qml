pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// AudioService — the default output, from the unit audio of the shell's application: its stream and
// question audio.status, every change and none lost, so a volume or a mute changed anywhere — a key,
// another mixer — shows at once; and its commands to set them.
//
// A slider dragged asks for many volumes in a row: the one asked shows at once, one command is in flight
// at a time, and only the last volume asked while it was is sent after it.
//
// ── Properties ────────────────────────────────────────────────────────────────
//   volume   — current volume level [0–150], as a person reads it; above 100 = overdrive
//   muted    — true when the default output is muted
//   output   — the default output's name for a person; "" when there is none
//
// ── API ───────────────────────────────────────────────────────────────────────
//   setVolume(vol)  — set volume (clamped to [0, 150])
//   toggleMute()    — toggle mute state
Singleton {
    id: root

    readonly property string unit: "audio"

    property var _output: null

    readonly property int volume: _asked >= 0 ? _asked : (_output ? _output.volume_pct : 0)
    readonly property bool muted: _output ? _output.mute : false
    readonly property string output: _output ? _output.description : ""

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    readonly property bool ready: _output !== null && _output !== undefined
    readonly property bool loading: !ready && error === ""
    readonly property string error: status.error || (status.joined && !ready ? "No default audio output" : "")

    function initialize(): void {}

    // ── Public API ────────────────────────────────────────────────────────────

    function setVolume(vol: int): void {
        if (!root.ready)
            return;
        root._asked = Math.max(0, Math.min(150, vol));
        if (!root._sending)
            root._send();
    }

    function toggleMute(): void {
        if (!root.ready)
            return;
        Yoke.link.command(unit, "audio.mute.set", JSON.stringify({ "id": _output.id, "mute": !_output.mute }), null,
                          refusal => console.warn("audio: mute refused: " + refusal.code));
    }

    // ── Internals ─────────────────────────────────────────────────────────────

    // The volume last asked and not yet seen in the status, or -1.
    property int _asked: -1
    property bool _sending: false
    property int _sent: -1

    function _send(): void {
        root._sending = true;
        root._sent = root._asked;
        Yoke.link.command(unit, "audio.volume.set", JSON.stringify({ "id": _output.id, "volume_pct": root._sent }),
                          ack => root._settled(), refusal => {
            console.warn("audio: volume refused: " + refusal.code);
            root._settled();
        });
    }

    function _settled(): void {
        root._sending = false;
        if (root._asked >= 0 && root._asked !== root._sent)
            root._send();
    }

    StreamJoin {
        id: status

        unit: root.unit
        stream: "audio.status"
        onValue: v => {
            root._output = v.output;
            // What was asked is now what is: the status speaks for it again.
            if (!root._sending && v.output && v.output.volume_pct === root._asked)
                root._asked = -1;
        }
    }

    // Should the status never come back to what was asked — another mixer moved it meanwhile — the status
    // speaks again once nothing is in flight.
    Timer {
        interval: 600
        running: root._asked >= 0 && !root._sending
        onTriggered: root._asked = -1
    }
}
