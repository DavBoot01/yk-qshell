pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string distroName: "Unknown"
    property string distroId: "unknown"
    property string distroIcon: "linux-symbolic"
    property string logo: "linux-symbolic"
    property string homeUrl: ""
    property string documentationUrl: ""
    property string supportUrl: ""
    property string bugReportUrl: ""
    property string privacyPolicyUrl: ""
    property string desktopEnvironment: ""
    property string windowingSystem: ""

    // Lifecycle
    property bool loading: false
    property bool ready: false
    property string error: ""

    // Internal: both async sources must complete before ready
    property bool _fileReady: false
    property bool _envReady: false

    // Idempotent: no-op if already loading or ready
    function initialize(): void {
        if (loading || ready) return
        loading = true
        error = ""
        _fileReady = false
        _envReady = false
        _osRelease.reload()
        _envProc.running = true
    }

    Component.onCompleted: initialize()

    function _checkReady(): void {
        if (_fileReady && _envReady) {
            loading = false
            ready = true
        }
    }

    // Source 1: /etc/os-release — parsed in onLoaded (async file read)
    FileView {
        id: _osRelease
        path: "/etc/os-release"
        watchChanges: false

        onLoaded: {
            const content = text()

            const get = (key) => {
                const m = content.match(new RegExp(`^${key}="?(.+?)"?$`, "m"))
                return m ? m[1] : ""
            }

            const prettyName = get("PRETTY_NAME")
            const name = get("NAME")
            root.distroName = prettyName || name.replace(/Linux/i, "").trim() || "Unknown"

            root.distroId = get("ID") || "unknown"
            root.homeUrl = get("HOME_URL")
            root.documentationUrl = get("DOCUMENTATION_URL")
            root.supportUrl = get("SUPPORT_URL")
            root.bugReportUrl = get("BUG_REPORT_URL")
            root.privacyPolicyUrl = get("PRIVACY_POLICY_URL")

            const logoField = get("LOGO")
            root.logo = logoField.trim().length > 0 ? logoField : root.distroIcon

            root._fileReady = true
            root._checkReady()
        }
    }

    // Source 2: environment variables (XDG_CURRENT_DESKTOP, WAYLAND_DISPLAY)
    Process {
        id: _envProc
        command: ["bash", "-c", "echo $XDG_CURRENT_DESKTOP,$WAYLAND_DISPLAY"]
        stdout: StdioCollector {
            id: _envCollector
            onStreamFinished: {
                const [desktop, wayland] = _envCollector.text.split(",")
                root.desktopEnvironment = desktop.trim()
                root.windowingSystem = wayland.trim().length > 0 ? "Wayland" : "X11"
                root._envReady = true
                root._checkReady()
            }
        }
    }
}
