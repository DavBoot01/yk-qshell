pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking

// WiFiService — visible network list and connection management through the
// native NetworkManager binding (Quickshell.Networking). No nmcli parsing.
//
// Current connection status (ssid, signal, ip, traffic) comes from Network.
// This service adds: visible network list, connect/disconnect actions.
//
// ── Properties ────────────────────────────────────────────────────────────────
//   networks      — [{ssid, signal, security, active, network}] sorted by active then signal
//   scanning      — true shortly after the panel opens / scan() is called
//   connectingTo  — ssid of the network being connected; "" when idle
//   connectError  — last connection error message; "" when none
//
// ── API ───────────────────────────────────────────────────────────────────────
//   scan()              — show the scanning state for a few seconds (manual refresh)
//   connect(ssid)       — connect to a saved network
//   disconnect()        — disconnect the wifi device
//
// The backend only lists nearby networks while the scanner is enabled, so the
// scanner runs for as long as the Wi-Fi tab of the right panel is open.
//
// Connecting to a NEW secured network needs a passphrase; that flow is not
// exposed yet, so such attempts report the backend's failure reason.
Singleton {
    id: root

    // First wifi device (null on machines without wifi).
    readonly property var _device: {
        for (const d of Networking.devices.values)
            if (d.type === DeviceType.Wifi) return d
        return null
    }

    // Recomputed whenever a network appears/disappears or any read property
    // (signal, connected state) changes.
    readonly property var networks: {
        if (!root._device) return []
        const seen = {}
        for (const n of root._device.networks.values) {
            if (!n.name) continue
            const entry = {
                ssid:     n.name,
                signal:   Math.round(n.signalStrength * 100),
                security: n.security === WifiSecurityType.Open ? "none"
                                                               : WifiSecurityType.toString(n.security),
                active:   n.connected,
                network:  n
            }
            const prev = seen[n.name]
            if (!prev || entry.signal > prev.signal) seen[n.name] = entry
        }
        // Active first, then descending signal
        return Object.values(seen).sort((a, b) =>
            a.active !== b.active ? (a.active ? -1 : 1) : b.signal - a.signal)
    }

    property bool   scanning:     false
    property string connectingTo: ""
    property string connectError: ""

    readonly property bool   ready:   root._device !== null
    readonly property bool   loading: false
    readonly property string error:   root.ready ? "" : "No Wi-Fi device"

    function initialize(): void {}

    // ── Public API ────────────────────────────────────────────────────────────

    function scan(): void {
        if (!root._device) return
        root.scanning     = true
        root.connectError = ""
        _scanStop.restart()
    }

    function connect(ssid: string): void {
        const entry = root.networks.find(e => e.ssid === ssid)
        if (!entry) return
        root.connectingTo = ssid
        root.connectError = ""
        entry.network.connect()
    }

    function disconnect(): void {
        if (root._device) root._device.disconnect()
    }

    // ── Internals ─────────────────────────────────────────────────────────────

    // Scanner follows the visibility of the Wi-Fi tab (saves power when closed).
    readonly property bool _wanted: PanelManager.activePanelId === "side-right"
        && PanelManager.activeContentId === "wifi"

    Binding {
        target:   root._device
        property: "scannerEnabled"
        value:    root._wanted
        when:     root._device !== null
    }

    on_WantedChanged: if (root._wanted) root.scan()

    // The spinner only needs to cover the first results arriving.
    Timer {
        id: _scanStop
        interval: 3000
        onTriggered: root.scanning = false
    }

    // Clear the "connecting" marker when the attempt ends; surface failures.
    Connections {
        target: root._device
        function onStateChanged(): void {
            if (root._device.connected) root.connectingTo = ""
        }
    }

    Instantiator {
        model: root._device ? root._device.networks : null
        delegate: Connections {
            required property var modelData
            target: modelData
            function onConnectionFailed(reason): void {
                root.connectingTo = ""
                root.connectError = ConnectionFailReason.toString(reason)
            }
            function onConnectedChanged(): void {
                if (modelData.connected && root.connectingTo === modelData.name)
                    root.connectingTo = ""
            }
        }
    }
}
