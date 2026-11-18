pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Wraps Hyprland workspace state with per-workspace status objects.
//
// ── Properties ────────────────────────────────────────────────────────────────
//   focusedId    — id of the currently focused workspace
//   minCount     — minimum workspaces to display even if empty (default: 9)
//   states       — JS array of { id, focused, occupied } for each visible workspace
//   occupiedIds  — sorted JS array of occupied workspace ids
//
// ── Methods ───────────────────────────────────────────────────────────────────
//   goTo(id)          — switch focus to workspace by id
//   moveWindowTo(id)  — move active window to workspace by id
//
// ── Lifecycle ─────────────────────────────────────────────────────────────────
//   Reactive passthrough — ready immediately after initialization.
//   initialize() is idempotent and called automatically on Component.onCompleted.
//
// ── Usage ─────────────────────────────────────────────────────────────────────
//   Repeater { model: Workspace.states }  — iterate all visible workspaces
//   Workspace.goTo(3)                     — jump to workspace 3
Singleton {
    id: root

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    property bool   loading: false
    property bool   ready:   false
    property string error:   ""

    function initialize(): void {
        if (ready) return
        ready = true
    }

    Component.onCompleted: initialize()

    // ── Configuration ─────────────────────────────────────────────────────────

    // Minimum number of workspace slots shown (even if no windows beyond this)
    property int minCount: 9

    // Currently focused workspace id (1-based)
    readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? 1

    // Sorted list of workspace ids that have at least one window
    readonly property var occupiedIds: {
        const ids = Hyprland.workspaces.values.map(w => w.id)
        ids.sort((a, b) => a - b)
        return ids
    }

    // Full range 1..N where N = max(minCount, highest occupied id, focused id)
    readonly property var displayIds: {
        const maxOccupied = root.occupiedIds.length > 0
            ? root.occupiedIds[root.occupiedIds.length - 1]
            : 0
        const maxId = Math.max(root.minCount, maxOccupied, root.focusedId)
        return Array.from({ length: maxId }, (_, i) => i + 1)
    }

    // Per-workspace state objects — iterate with Repeater { model: Workspace.states }
    // Each object: { id: int, focused: bool, occupied: bool }
    // The focused workspace is always considered occupied.
    readonly property var states: {
        const occupiedSet = new Set(root.occupiedIds)
        return root.displayIds.map(id => ({
            id,
            focused:  id === root.focusedId,
            occupied: occupiedSet.has(id) || id === root.focusedId
        }))
    }

    // Switch to workspace by id
    function goTo(id: int): void {
        Hyprland.dispatch("workspace " + id)
    }

    // Move the currently focused window to workspace by id
    function moveWindowTo(id: int): void {
        Hyprland.dispatch("movetoworkspace " + id)
    }
}
