pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Battery state from UPower (native binding, event-driven — no polling).
//
// ── Properties ────────────────────────────────────────────────────────────────
//   present        — false when no battery is detected (desktop/VM)
//   percent        — charge level [0–100]
//   status         — "Charging" | "Discharging" | "Full" | "Empty" | "Unknown"
//   charging       — true when status is Charging
//   full           — true when status is Full
//   powerNow       — current power draw/charge rate in watts
//   healthPercent  — battery health [0–100] (100 when unsupported)
//   timeToEmpty    — estimated minutes remaining while discharging (-1 = unknown)
//   timeToFull     — estimated minutes until full while charging  (-1 = unknown)
Singleton {
    id: root

    readonly property UPowerDevice _dev: UPower.displayDevice

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    readonly property bool   ready:   root._dev !== null && root._dev.ready
    readonly property bool   loading: !root.ready
    readonly property string error:   ""

    // Nothing to start — kept for the uniform service lifecycle.
    function initialize(): void {}

    // ── Public state ──────────────────────────────────────────────────────────
    readonly property bool present: root.ready && root._dev.isPresent && root._dev.isLaptopBattery
    readonly property int  percent: root.ready ? Math.round(root._dev.percentage * 100) : 0

    readonly property string status: {
        if (!root.ready) return "Unknown"
        switch (root._dev.state) {
        case UPowerDeviceState.Charging:
        case UPowerDeviceState.PendingCharge:    return "Charging"
        case UPowerDeviceState.Discharging:
        case UPowerDeviceState.PendingDischarge: return "Discharging"
        case UPowerDeviceState.FullyCharged:     return "Full"
        case UPowerDeviceState.Empty:            return "Empty"
        default:                                 return "Unknown"
        }
    }

    readonly property bool charging: root.status === "Charging"
    readonly property bool full:     root.status === "Full"

    readonly property real powerNow:      root.ready ? Math.abs(root._dev.changeRate) : 0.0
    readonly property int  healthPercent: root.ready && root._dev.healthSupported
        ? Math.round(root._dev.healthPercentage) : 100

    // UPower reports seconds; 0 means unknown.
    readonly property int timeToEmpty: root.ready && root.status === "Discharging" && root._dev.timeToEmpty > 0
        ? Math.round(root._dev.timeToEmpty / 60) : -1
    readonly property int timeToFull:  root.ready && root.status === "Charging" && root._dev.timeToFull > 0
        ? Math.round(root._dev.timeToFull / 60) : -1
}
