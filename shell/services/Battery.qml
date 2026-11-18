pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Yoke.Interface

// The battery, from the unit power of the shell's application: its stream power.status, every change and
// none lost, and its question power.status for the present. Nothing here speaks to UPower.
//
// It joins the present to what follows without a gap: it opens the delivery, starts the stream, and only
// then asks the status; frames arriving meanwhile are held, and those at or below the sequence the answer
// states are dropped. On every attachment it joins again.
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
    property string error: ""

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

    // ── Joining the stream ────────────────────────────────────────────────────
    property var _status: null
    property var _held: []
    property var _at: undefined
    property bool _joining: false

    function _join(): void {
        if (_joining || !Yoke.attached || !delivery.open)
            return;
        _joining = true;
        _held = [];
        _at = undefined;
        Yoke.link.startStream(unit, "power.status", null,
                              refusal => console.warn("battery: power.status not started: " + refusal.code));
        Yoke.link.ask(unit, "power.status", "{}", answer => {
            const present = Yoke.json(answer);
            if (!present)
                return;
            error = "";
            _at = present.sequence;
            _status = present;
            const held = _held;
            _held = null;
            for (const v of held)
                _apply(v);
        }, refusal => {
            console.warn("battery: power.status refused: " + refusal.code);
            error = "power refused its status: " + refusal.code;
            _joining = false;
        });
    }

    function _apply(value: var): void {
        if (_at !== undefined && value.sequence <= _at)
            return;
        _at = value.sequence;
        _status = value;
    }

    Connections {
        target: Yoke
        function onAttachedChanged(): void {
            root._joining = false;
            root._join();
        }
    }

    Delivery {
        id: delivery

        attachment: Yoke.link
        unit: root.unit
        stream: "power.status"
        onOpenChanged: root._join()
        onFrame: frame => {
            const value = Yoke.json(frame.payload);
            if (!value)
                return;
            if (root._held !== null)
                root._held.push(value);
            else
                root._apply(value);
        }
    }
}
