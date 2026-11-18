pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// PanelManager — central routing layer for overlay panels.
//
// Any source (widget click, keyboard shortcut, IPC) calls toggle/open/close
// to drive any panel window.  Panel containers react to activePanelId.
//
// ── Toggle semantics ──────────────────────────────────────────────────────────
//   same (panelId + contentId) → close
//   same panelId, different contentId → switch content (panel stays open)
//   different panelId → close current, open new
//
// ── Usage from a widget ───────────────────────────────────────────────────────
//   BarChip {
//       panelId:        "center-dropdown"
//       panelContentId: "network"
//       panelContent:   Component { NetworkDetailPanel {} }
//       …
//   }
//
// ── Usage from a keyboard shortcut / IPC ─────────────────────────────────────
//   property Component _netContent: Component { NetworkDetailPanel {} }
//   IpcHandler {
//       function toggleNetwork(): void {
//           PanelManager.toggle("center-dropdown", "network", _netContent)
//       }
//   }
//
// ── Panel container side ──────────────────────────────────────────────────────
//   visible: PanelManager.activePanelId === "center-dropdown"
//   // Keep a local copy of activeContent (Binding { when: <this panel active> })
//   // so the content survives the close animation even if another panel opens.
//
// ── Panel ids ─────────────────────────────────────────────────────────────────
//   "center-dropdown", "side-right", "side-left"
//   Only one panel is open at a time: opening one closes the others.
Singleton {
    id: root

    // Which panel window is currently open.  Empty string = all panels closed.
    property string    activePanelId:   ""

    // Identity key of the active content slot — used for toggle detection.
    property string    activeContentId: ""

    // The Component rendered inside the active panel.
    // Stays set after close() — panels keep their own copy for the close animation.
    property Component activeContent:   null

    // The ShellScreen on which the active panel should appear.
    // Initialized to the first available screen so PanelWindow always has a
    // valid binding; updated to the clicked screen on every open/toggle call.
    property var activeScreen: null

    Component.onCompleted: {
        // Populate with first screen so PanelWindow has a valid screen from startup.
        // Quickshell.screens is always populated by the time singletons initialize.
        if (activeScreen === null && Quickshell.screens.values.length > 0)
            activeScreen = Quickshell.screens.values[0]
    }

    // ── Public API ────────────────────────────────────────────────────────────

    function open(panelId, contentId, content, screen) {
        root.activeScreen    = screen ?? root.activeScreen
        root.activePanelId   = panelId
        root.activeContentId = contentId
        root.activeContent   = content
    }

    function close() {
        root.activePanelId   = ""
        root.activeContentId = ""
        // activeScreen and activeContent kept alive during close animation
    }

    function toggle(panelId, contentId, content, screen) {
        if (root.activePanelId === panelId && root.activeContentId === contentId)
            root.close()
        else
            root.open(panelId, contentId, content, screen)
    }
}
