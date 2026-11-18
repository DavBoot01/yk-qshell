pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// The battery, from the unit power of the shell's application: its stream power.status, every change and
// none lost, and its question power.status for the present. Nothing here speaks to UPower.
//
// It joins the present to what follows without a gap, as StreamJoin does; on every attachment it joins again.
//
// ── Properties ────────────────────────────────────────────────────────────────
//   present        — false when no battery is detected (desktop/VM)
//   percent        — charge level [0–100]
//   status         — "Charging" | "Discharging" | "Full" | "Empty" | "Unknown"
//   charging       — true when status is Charging
//   full           — true when status is Full
//   onBattery      — the host runs on its battery
//   powerNow       — current power draw/charge rate in watts
//   healthPercent  — 100: power does not report a battery's health
//   timeToEmpty    — estimated minutes remaining while discharging (-1 = unknown)
//   timeToFull     — estimated minutes until full while charging  (-1 = unknown)
Singleton {
    id: root

    readonly property string unit: "power"

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    readonly property bool ready: _status !== null
    readonly property bool loading: !ready && error === ""
    readonly property string error: join.error

    // Derived from the attachment and the unit — nothing to start.
    function initialize(): void {}

    // ── Public state ──────────────────────────────────────────────────────────
    readonly property var _battery: _status ? _status.battery : null

    readonly property bool present: _battery !== null && _battery !== undefined
    readonly property int percent: present ? Math.round(_battery.percentage) : 0
    readonly property bool onBattery: _status ? _status.on_battery : false

    readonly property string status: {
        if (!present)
            return "Unknown";
        switch (_battery.state) {
        case "charging":
        case "pending-charge":
            return "Charging";
        case "discharging":
        case "pending-discharge":
            return "Discharging";
        case "fully-charged":
            return "Full";
        case "empty":
            return "Empty";
        default:
            return "Unknown";
        }
    }

    readonly property bool charging: status === "Charging"
    readonly property bool full: status === "Full"

    readonly property real powerNow: present && _battery.energy_rate !== undefined ? Math.abs(_battery.energy_rate) : 0.0
    readonly property int healthPercent: 100

    // power reports seconds; 0 means unknown.
    readonly property int timeToEmpty: present && status === "Discharging" && _battery.time_to_empty > 0
        ? Math.round(_battery.time_to_empty / 60) : -1
    readonly property int timeToFull: present && status === "Charging" && _battery.time_to_full > 0
        ? Math.round(_battery.time_to_full / 60) : -1

    property var _status: null

    StreamJoin {
        id: join

        unit: root.unit
        stream: "power.status"
        onValue: v => root._status = v
    }
}
