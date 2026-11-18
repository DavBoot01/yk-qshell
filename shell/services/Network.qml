pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Network state from the native NetworkManager binding (Quickshell.Networking),
// plus /proc/net/dev for traffic.
//
// Connection state is event-driven (no polling, no nmcli parsing). The only
// external command is a one-shot `nmcli` call to read the IPv4 address, run when
// the active interface changes (the binding does not expose IP addresses).
//
// ── Traffic poll (2 s) ───────────────────────────────────────────────────────
// Reads /proc/net/dev (FileView) for the active interface and computes a
// bytes/s delta against the previous sample.
//
// ── Properties ───────────────────────────────────────────────────────────────
// Summary
//   connected      — true if any wifi or ethernet interface is active
//   type           — "wifi" | "ethernet" | "none"
//   ssid           — Wi-Fi SSID or ethernet connection name; "" if none
//   ipAddress      — IPv4 address (e.g. "192.168.1.14"); "" if disconnected
//   wifiSignal     — signal strength [0–100]; 0 for non-wifi
//
// Traffic  (raw bytes/s; format in the widget)
//   rxBytesPerSec  — receive rate
//   txBytesPerSec  — transmit rate
Singleton {
    id: root

    // ── Active interface ──────────────────────────────────────────────────────
    // First connected wifi/wired device; re-evaluated on any device change.
    readonly property var _primary: {
        for (const d of Networking.devices.values) {
            if (d.connected && (d.type === DeviceType.Wifi || d.type === DeviceType.Wired))
                return d
        }
        return null
    }

    readonly property bool _isWifi: root._primary !== null && root._primary.type === DeviceType.Wifi

    // The Network object the device is currently connected to (wifi) or its link.
    readonly property var _activeNetwork: {
        const d = root._primary
        if (!d) return null
        if (!root._isWifi) return d.network ?? null
        for (const n of d.networks.values)
            if (n.connected) return n
        return null
    }

    // ── Connection summary ────────────────────────────────────────────────────
    readonly property bool   connected:  root._primary !== null
    readonly property string type:       root._primary === null ? "none"
                                         : (root._isWifi ? "wifi" : "ethernet")
    readonly property string ssid:       root._activeNetwork?.name ?? (root._primary?.name ?? "")
    readonly property int    wifiSignal: root._isWifi && root._activeNetwork
                                         ? Math.round(root._activeNetwork.signalStrength * 100) : 0
    property string ipAddress: ""

    // ── Traffic ───────────────────────────────────────────────────────────────
    property int rxBytesPerSec: 0
    property int txBytesPerSec: 0

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    // The native binding is event-driven; ready once the backend is up.
    readonly property bool   ready:   Networking.backend !== NetworkBackendType.None
    readonly property bool   loading: !root.ready
    readonly property string error:   root.ready ? "" : "No network backend"

    function initialize(): void {
        if (_trafficTimer.running) return
        _trafficTimer.running = true
    }

    Component.onCompleted: initialize()

    // ── IPv4 address ──────────────────────────────────────────────────────────
    readonly property string _deviceName: root._primary?.name ?? ""

    on_DeviceNameChanged: {
        root.ipAddress = ""
        root._prevRx = 0
        root._prevTx = 0
        root._prevTime = 0
        root.rxBytesPerSec = 0
        root.txBytesPerSec = 0
        if (root._deviceName !== "") _ipDelay.restart()
    }

    // Give NetworkManager a moment to finish DHCP before asking for the address.
    Timer { id: _ipDelay; interval: 1500; onTriggered: _ipProc.running = true }

    Process {
        id: _ipProc
        command: ["nmcli", "-t", "-f", "IP4.ADDRESS", "dev", "show", root._deviceName]
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/^IP4\.ADDRESS\[1\]:([\d.]+)/)
                if (m) root.ipAddress = m[1]
            }
        }
    }

    // ── Traffic sampling ──────────────────────────────────────────────────────
    property real _prevRx:   0
    property real _prevTx:   0
    property real _prevTime: 0

    Timer {
        id: _trafficTimer
        interval: 2000
        running:  false
        repeat:   true
        onTriggered: if (root._deviceName !== "") root._sampleTraffic()
    }

    // rx/tx bytes of the active interface from /proc/net/dev.
    FileView { id: _netDev; path: "/proc/net/dev"; blockLoading: true }

    function _sampleTraffic(): void {
        _netDev.reload()
        const prefix = root._deviceName + ":"
        for (const line of _netDev.text().split("\n")) {
            const t = line.trim()
            if (!t.startsWith(prefix)) continue
            // "<dev>: rx_bytes … (8 rx fields) tx_bytes …"
            const f  = t.slice(prefix.length).trim().split(/\s+/)
            const rx = parseFloat(f[0])
            const tx = parseFloat(f[8])
            const now = Date.now()

            if (root._prevTime > 0 && rx >= root._prevRx && tx >= root._prevTx) {
                const dt = (now - root._prevTime) / 1000   // seconds
                if (dt > 0) {
                    root.rxBytesPerSec = Math.round((rx - root._prevRx) / dt)
                    root.txBytesPerSec = Math.round((tx - root._prevTx) / dt)
                }
            }
            root._prevRx   = rx
            root._prevTx   = tx
            root._prevTime = now
            return
        }
    }
}
