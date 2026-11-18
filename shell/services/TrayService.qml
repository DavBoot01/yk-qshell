pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

// Wraps Quickshell's SystemTray singleton.
// Consumers import this service rather than Quickshell.Services.SystemTray directly.
//
// ── Lifecycle ─────────────────────────────────────────────────────────────────
//   Reactive passthrough — ready immediately after initialization.
//   initialize() is idempotent and called automatically on Component.onCompleted.
//
// ── Properties ────────────────────────────────────────────────────────────────
//   items        — ObjectModel (use in Repeater): all registered tray items
//   activeItems  — JS array: Active + NeedsAttention only, no Passive items
//
// ── Helpers ───────────────────────────────────────────────────────────────────
//   tooltipFor(item) — best available tooltip string for a tray item
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

    // ── Data ──────────────────────────────────────────────────────────────────

    // ObjectModel — pass directly to Repeater { model: TrayService.items }.
    readonly property var items: SystemTray.items

    // Filtered JS array — excludes background-only (Passive) items.
    // Re-evaluated whenever the items model changes.
    readonly property var activeItems: SystemTray.items.values
        .filter(i => i.status !== Status.Passive)

    // Returns the most descriptive available tooltip string for a tray item.
    function tooltipFor(item): string {
        if (item.tooltipTitle) {
            return item.tooltipDescription
                ? item.tooltipTitle + ": " + item.tooltipDescription
                : item.tooltipTitle
        }
        return item.title
    }
}
