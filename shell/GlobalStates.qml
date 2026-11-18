pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// GlobalStates — central UI state for the shell.
//
// Pure in-memory state: no async loading, always ready.
// Accessible from any component via `import qs`.
//
// Exempted from the standard service lifecycle (loading/ready/error) because
// it holds only reactive in-process values, not data loaded from external sources.
Singleton {
    id: root

    // ── Bar ───────────────────────────────────────────────────────────────────
    // true  = bar is active (subject to auto-hide rules if enabled).
    // false = bar is fully dismissed (fullscreen override, user toggle, etc.)
    property bool barOpen: true

    // Overlay/side panels are routed by PanelManager (services/), not here.

    // ── OSD / transient overlays ──────────────────────────────────────────────
    property bool osdVolumeOpen:     false
    property bool osdBrightnessOpen: false
    property bool overviewOpen:      false

    // ── System state ──────────────────────────────────────────────────────────
    property bool screenLocked: false

    // ── Keyboard modifier state ───────────────────────────────────────────────
    // True while the Super/Meta key is physically held down.
    // Set from shell.qml via Hyprland IPC or a key-tracking mechanism.
    // Used by BarContainer's super-reveal timer when autoHide.showOnSuper is true.
    property bool superDown: false
}
