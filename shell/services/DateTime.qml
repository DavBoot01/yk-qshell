pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// Provides current time and date as reactive properties.
// Updates every second via an internal Timer.
// No lifecycle needed — values are always ready (computed from new Date()).
Singleton {
    id: root

    // ── Time components ───────────────────────────────────────────────────────
    readonly property int hours:   _now.getHours()
    readonly property int minutes: _now.getMinutes()
    readonly property int seconds: _now.getSeconds()

    // ── Formatted convenience strings ─────────────────────────────────────────
    // HH:mm  — suitable for compact bar display
    readonly property string time: Qt.formatTime(_now, "HH:mm")
    // ddd d MMM  — e.g. "Mon 13 Apr"
    readonly property string date: Qt.formatDate(_now, "ddd d MMM")

    // ── Internal clock ────────────────────────────────────────────────────────
    property var _now: new Date()

    Timer {
        interval: 1000
        running:  true
        repeat:   true
        onTriggered: root._now = new Date()
    }
}
