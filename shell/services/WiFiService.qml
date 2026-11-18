pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// WiFiService — the networks in range and the connection's management, from the unit network of the
// shell's application: its stream network.scan, flowing while the Wi-Fi tab of the right panel is open, in
// which the manager is asked to scan; its commands to connect and disconnect; and network.status, which
// says how a connection being made went.
//
// Current connection status (ssid, signal, ip, traffic) comes from Network.
//
// ── Properties ────────────────────────────────────────────────────────────────
//   networks      — [{ssid, signal, security, active}] sorted by active then signal
//   scanning      — true shortly after the panel opens / scan() is called
//   connectingTo  — ssid of the network being connected; "" when idle
//   connectError  — last connection error message; "" when none
//
// ── API ───────────────────────────────────────────────────────────────────────
//   scan()              — ask the manager to scan again
//   connect(ssid)       — connect: a saved profile when there is one, otherwise an open network
//   disconnect()        — disconnect the Wi-Fi device
//
// Connecting to a NEW secured network needs a passphrase; that flow is not exposed yet, so such attempts
// report the manager's failure.
Singleton {
    id: root

    readonly property string unit: "network"

    property var networks: []
    property bool scanning: false
    property string connectingTo: ""
    property string connectError: ""

    readonly property bool ready: Yoke.attached
    readonly property bool loading: false
    readonly property string error: scan.error

    function initialize(): void {}

    // ── Public API ────────────────────────────────────────────────────────────

    function scan(): void {
        root.scanning = true;
        root.connectError = "";
        _scanStop.restart();
        Yoke.link.command(unit, "network.wifi.scan", "{}", null,
                          refusal => console.warn("wifi: scan refused: " + refusal.code));
    }

    function connect(ssid: string): void {
        const entry = root.networks.find(e => e.ssid === ssid);
        if (!entry)
            return;
        root.connectingTo = ssid;
        root.connectError = "";
        // A saved profile is activated as it is; an unsaved network is joined only where it is open.
        Yoke.link.ask(unit, "network.profiles", "{}", answer => {
            const saved = (Yoke.json(answer)?.profiles ?? []).find(p => p.ssid === ssid);
            if (saved)
                root._command("network.profiles.activate", { "uuid": saved.uuid });
            else
                root._command("network.wifi.connect", { "ssid": ssid, "security": entry.securityName });
        }, refusal => root._failed("the profiles cannot be read: " + refusal.code));
    }

    function disconnect(): void {
        root._command("network.wifi.disconnect", {});
    }

    // ── Internals ─────────────────────────────────────────────────────────────

    function _command(type: string, payload: var): void {
        Yoke.link.command(unit, type, JSON.stringify(payload), ack => {
            if (ack.outcome === "OUTCOME_FAILED")
                root._failed(ack.line);
        }, refusal => root._failed(refusal.message || refusal.code));
    }

    function _failed(why: string): void {
        root.connectingTo = "";
        root.connectError = why;
    }

    function _show(sample: var): void {
        const seen = {};
        for (const a of sample.access_points ?? []) {
            if (!a.ssid)
                continue;
            const entry = {
                "ssid": a.ssid,
                "signal": a.signal_pct,
                "security": a.security === "open" ? "none" : a.security,
                "securityName": a.security,
                "active": a.in_use
            };
            const prev = seen[a.ssid];
            if (!prev || entry.signal > prev.signal || entry.active)
                seen[a.ssid] = Object.assign(entry, { "active": entry.active || (prev ? prev.active : false) });
        }
        // Active first, then descending signal.
        root.networks = Object.values(seen).sort((a, b) => a.active !== b.active ? (a.active ? -1 : 1) : b.signal - a.signal);
    }

    // The scan flows, and the manager scans, only while the Wi-Fi tab is open.
    readonly property bool _wanted: PanelManager.activePanelId === "side-right" && PanelManager.activeContentId === "wifi"

    on_WantedChanged: if (root._wanted) root.scan()

    StreamJoin {
        id: scan

        unit: root.unit
        stream: "network.scan"
        question: "network.access-points"
        wanted: root._wanted
        onValue: v => root._show(v)
    }

    // A connection being made ends in the status: connected to the network asked for, or failed.
    StreamJoin {
        unit: root.unit
        stream: "network.status"
        onValue: v => {
            if (root.connectingTo === "")
                return;
            if (v.phase === "connected" && v.connection && v.connection.ssid === root.connectingTo)
                root.connectingTo = "";
            else if (v.phase === "failed")
                root._failed(v.error ? (v.error.detail || v.error.code) : "the connection failed");
        }
    }

    // The spinner only needs to cover the first results arriving.
    Timer {
        id: _scanStop
        interval: 3000
        onTriggered: root.scanning = false
    }
}
