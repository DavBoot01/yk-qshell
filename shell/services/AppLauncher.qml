pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Abstracts the app launcher so callers do not depend on a specific implementation.
// Currently backed by rofi; swap the command here to change the launcher globally.
Singleton {
    id: root

    function launch() {
        if (!_proc.running) _proc.running = true
    }

    Process {
        id: _proc
        command: ["rofi", "-show", "drun"]
    }
}
