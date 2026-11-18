pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// Bluetooth, from the unit bluetooth of the shell's application: the adapter, the devices connected and a
// pairing waiting for the person from its stream and question bluetooth.status, every change and none
// lost; the devices known and those in range, from bluetooth.devices and bluetooth.scan, flowing only
// while the Bluetooth tab of the right panel is open — the adapter discovers only while the scan flows.
//
// Pairing asks the person: when BlueZ needs a PIN, a passkey or a confirmation, the status carries
// `pairing` until it is answered with answerPairing(), or rejected by the Plugin after 60 s.
//
// ── Properties ────────────────────────────────────────────────────────────────
//   available      — an adapter is there
//   powered        — the adapter is on
//   connected      — [{address, alias, icon, battery}] the devices connected
//   devices        — [{address, alias, icon, paired, trusted, connected, battery}] the paired devices
//   discovered     — [{address, alias, icon, rssi}] devices in range not paired, strongest first
//   pairing        — {request_id, address, alias, kind, passkey?, pin?, answers} or null
//   busy           — the address a command is being carried out on; "" when idle
//   lastError      — the last command's failure; "" when none
//
// ── API ───────────────────────────────────────────────────────────────────────
//   setPowered(on), connect(address), disconnect(address), pair(address), forget(address)
//   answerPairing(accept, code)   — code is the PIN or the passkey where the kind asks for one
Singleton {
    id: root

    readonly property string unit: "bluetooth"

    property var _status: null
    property var _devices: []
    property var _inRange: []

    readonly property bool available: _status !== null && _status.adapter !== null && _status.adapter !== undefined
    readonly property bool powered: available && _status.adapter.powered
    readonly property var connected: _status ? (_status.connected ?? []) : []
    readonly property var pairing: _status ? (_status.pairing ?? null) : null
    readonly property var devices: _devices.filter(d => d.paired)
        .sort((a, b) => a.connected !== b.connected ? (a.connected ? -1 : 1) : a.alias.localeCompare(b.alias))
    readonly property var discovered: _inRange.filter(d => !d.paired)
        .sort((a, b) => (b.rssi ?? -200) - (a.rssi ?? -200))

    property string busy: ""
    property string lastError: ""

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    readonly property bool ready: _status !== null
    readonly property bool loading: !ready && error === ""
    readonly property string error: status.error

    function initialize(): void {}

    // ── API ───────────────────────────────────────────────────────────────────
    function setPowered(on: bool): void {
        _command("bluetooth.power", { "on": on }, "");
    }
    function connect(address: string): void {
        _command("bluetooth.connect", { "address": address }, address);
    }
    function disconnect(address: string): void {
        _command("bluetooth.disconnect", { "address": address }, address);
    }
    function pair(address: string): void {
        _command("bluetooth.pair", { "address": address }, address);
    }
    function forget(address: string): void {
        _command("bluetooth.forget", { "address": address }, address);
    }
    // The code goes back in the command's payload and is kept nowhere here.
    function answerPairing(accept: bool, code: string): void {
        const p = root.pairing;
        if (!p)
            return;
        const answer = { "request_id": p.request_id, "accept": accept };
        if (accept && p.kind === "pin")
            answer.pin = code;
        else if (accept && p.kind === "passkey")
            answer.passkey = parseInt(code, 10);
        _command("bluetooth.pairing.answer", answer, "");
    }

    function _command(type: string, payload: var, address: string): void {
        root.busy = address;
        root.lastError = "";
        Yoke.link.command(unit, type, JSON.stringify(payload), ack => {
            // `accepted` means it is still running: what it came to is in the status and the devices.
            if (ack.outcome !== "OUTCOME_ACCEPTED")
                root.busy = "";
            if (ack.outcome === "OUTCOME_FAILED")
                root.lastError = ack.line;
        }, refusal => {
            root.busy = "";
            root.lastError = refusal.message || refusal.code;
        });
    }

    // The panel is open: the known devices flow, and the adapter discovers.
    readonly property bool _wanted: PanelManager.activePanelId === "side-right" && PanelManager.activeContentId === "bluetooth"

    StreamJoin {
        id: status

        unit: root.unit
        stream: "bluetooth.status"
        onValue: v => {
            root._status = v;
            if (root.busy !== "" && (v.connected ?? []).some(d => d.address === root.busy))
                root.busy = "";
        }
    }

    StreamJoin {
        unit: root.unit
        stream: "bluetooth.devices"
        wanted: root._wanted
        onValue: v => root._devices = v.devices ?? []
    }

    StreamJoin {
        unit: root.unit
        stream: "bluetooth.scan"
        question: "bluetooth.devices"
        wanted: root._wanted && root.powered
        onValue: v => root._inRange = v.devices ?? []
    }

    // A pair or a connect still running ends in the devices: clear the marker when it does.
    onDevicesChanged: if (root.busy !== "" && root._devices.some(d => d.address === root.busy && (d.paired || d.connected)))
        root.busy = ""
}
