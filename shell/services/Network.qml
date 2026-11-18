pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// The network, from the unit network of the shell's application: the connection from its stream and
// question network.status, every change and none lost; the signal and the traffic from network.link, a
// reading every 2 s while it flows. Nothing here speaks to NetworkManager or reads /proc.
//
// ── Properties ───────────────────────────────────────────────────────────────
// Summary
//   connected      — true if a Wi-Fi or Ethernet device is the host's link
//   type           — "wifi" | "ethernet" | "none"
//   ssid           — Wi-Fi SSID or the device's name for Ethernet; "" if none
//   ipAddress      — IPv4 address (e.g. "192.168.1.14"); "" if disconnected
//   wifiSignal     — signal strength [0–100]; 0 for non-wifi
//
// Traffic  (raw bytes/s; format in the widget)
//   rxBytesPerSec  — receive rate
//   txBytesPerSec  — transmit rate
Singleton {
    id: root

    readonly property string unit: "network"

    property var _status: null
    property var _link: null
    readonly property var _connection: _status && _status.phase === "connected" ? _status.connection : null

    // ── Connection summary ────────────────────────────────────────────────────
    readonly property bool connected: _connection !== null && _connection !== undefined
    readonly property string type: {
        if (!connected)
            return "none";
        const kind = _connection.kind ?? (_link ? _link.kind : "");
        return kind === "wifi" ? "wifi" : kind === "ethernet" ? "ethernet" : "none";
    }
    readonly property string ssid: connected ? (_connection.ssid ?? _connection.device ?? "") : ""
    readonly property string ipAddress: connected && _connection.ip4 ? _connection.ip4.split("/")[0] : ""
    readonly property int wifiSignal: type === "wifi" && _link && _link.signal_pct !== null ? _link.signal_pct : 0

    // ── Traffic ───────────────────────────────────────────────────────────────
    readonly property int rxBytesPerSec: _link && _link.rx_bytes_per_s !== null ? _link.rx_bytes_per_s : 0
    readonly property int txBytesPerSec: _link && _link.tx_bytes_per_s !== null ? _link.tx_bytes_per_s : 0

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    readonly property bool ready: _status !== null
    readonly property bool loading: !ready && error === ""
    readonly property string error: status.error || link.error

    function initialize(): void {}

    StreamJoin {
        id: status

        unit: root.unit
        stream: "network.status"
        onValue: v => root._status = v
    }

    StreamJoin {
        id: link

        unit: root.unit
        stream: "network.link"
        onValue: v => root._link = v
    }
}
