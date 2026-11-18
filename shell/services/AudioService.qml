pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// AudioService — default audio sink control via the native PipeWire binding.
//
// Event-driven: volume/mute changes made anywhere (keyboard, other mixers)
// are reflected immediately, with no polling and no external process.
//
// ── Properties ────────────────────────────────────────────────────────────────
//   volume   — current volume level [0–150]; values above 100 = overdrive
//   muted    — true when the default sink is muted
//
// ── API ───────────────────────────────────────────────────────────────────────
//   setVolume(vol)  — set volume (clamped to [0, 150])
//   toggleMute()    — toggle mute state
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink

    readonly property int  volume: root.sink?.audio ? Math.round(root.sink.audio.volume * 100) : 0
    readonly property bool muted:  root.sink?.audio ? root.sink.audio.muted : false

    // Native binding: ready as soon as a default sink with audio is bound.
    readonly property bool   ready:   root.sink !== null && root.sink.audio !== null
    readonly property bool   loading: !root.ready
    readonly property string error:   root.ready ? "" : "No default audio sink"

    // Nothing to start — kept for the uniform service lifecycle.
    function initialize(): void {}

    // The sink's audio properties are only valid while the node is tracked.
    PwObjectTracker { objects: [root.sink] }

    // ── Public API ────────────────────────────────────────────────────────────

    function setVolume(vol: int): void {
        if (!root.ready) return
        root.sink.audio.volume = Math.max(0, Math.min(150, vol)) / 100
    }

    function toggleMute(): void {
        if (!root.ready) return
        root.sink.audio.muted = !root.sink.audio.muted
    }
}
