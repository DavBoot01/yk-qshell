//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs
import qs.themes
import qs.services
import qs.containers
import qs.modules.bar
import qs.modules.notifications

ShellRoot {
    id: root

    Scope {
        // Always-visible panels
        Bar {}

        // Center-pill overlay dropdown
        CenterDropdown {}

        // Right side panel (audio / wifi) — content comes from PanelManager
        SidePanelRight {}

        // Notifications over the screen as they come, from the Plugin that is the session's server
        NotificationPopups {}

        // ── Bar IPC ───────────────────────────────────────────────────────────
        // Control bar visibility from the compositor or external tools:
        //   qs ipc call myshell bar toggle
        //   qs ipc call myshell bar open
        //   qs ipc call myshell bar close
        //
        // Hyprland example bindings (hyprland.conf):
        //   bind = SUPER, F1, exec, qs ipc call myshell bar toggle
        IpcHandler {
            target: "bar"
            function toggle(): void { GlobalStates.barOpen = !GlobalStates.barOpen }
            function open():   void { GlobalStates.barOpen = true }
            function close():  void { GlobalStates.barOpen = false }
        }

        // ── Theme IPC ─────────────────────────────────────────────────────────
        //   qs ipc call theme set catppuccin-latte
        //   qs ipc call theme list
        IpcHandler {
            target: "theme"
            function set(name: string): void { Theme.themeName = name }
            function list(): string { return Theme.names.join("\n") }
        }

        // ── Super-key tracking ────────────────────────────────────────────────
        // Set GlobalStates.superDown from Hyprland IPC when the Meta key is held.
        // Example (hyprland.conf):
        //   bind = SUPER, catchall, exec, qs ipc call myshell superDown press
        //   bindr = SUPER, Super_L, exec, qs ipc call myshell superDown release
        IpcHandler {
            target: "superDown"
            function press():   void { GlobalStates.superDown = true }
            function release(): void { GlobalStates.superDown = false }
        }
    }

    // Bootstrap: singletons are created lazily on first reference, so touching
    // them here makes startup eager and the dependency list auditable.
    // initialize() is idempotent (services also call it from Component.onCompleted).
    Component.onCompleted: {
        Translation.initialize()
        SystemInfo.initialize()
        SystemStats.initialize()
        Network.initialize()
        Battery.initialize()
        TrayService.initialize()
        Workspace.initialize()
        AudioService.initialize()
        WiFiService.initialize()
        BluetoothService.initialize()
        Notifications.initialize()
    }

}
