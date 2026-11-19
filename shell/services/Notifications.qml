pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// The desktop's notifications, from the unit notifications of the shell's application, which is the
// session's notification server: its stream notifications.list, the whole record at every change, joined to
// its question of the same name through StreamJoin; its commands to dismiss, answer, mark seen and quiet.
// The shell keeps nothing of its own: what is listed, seen or quiet is the Plugin's.
//
// ── Properties ────────────────────────────────────────────────────────────────
//   list        — every notification held, newest first, as the Plugin states it:
//                 { id, app, desktop_entry, icon, image, summary, body, default_action, actions: [{key, label}],
//                   urgency, category, at, expire_ms, transient, resident, seen, quiet }
//   unseen      — how many are not seen yet
//   dnd         — do-not-disturb holds
//   held        — the Plugin holds the session's notification server; serverLine says why not
//
// ── Signals ───────────────────────────────────────────────────────────────────
//   arrived(n)  — a notification came, or replaced one, since the shell attached: what a popup shows
Singleton {
    id: root

    readonly property string unit: "notifications"

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    readonly property bool ready: _record !== null
    readonly property bool loading: !ready && error === ""
    readonly property string error: join.error

    function initialize(): void {}

    // ── The record ────────────────────────────────────────────────────────────
    property var _record: null

    readonly property var list: _record && _record.notifications ? _record.notifications : []
    readonly property int unseen: _record ? _record.unseen : 0
    readonly property bool dnd: _record ? _record.dnd : false
    readonly property bool held: _record && _record.server ? _record.server.held : false
    readonly property string serverLine: _record && _record.server ? _record.server.line : ""

    signal arrived(var n)

    // What each notification was when last seen, by id: its time, so that a replacement shows again.
    property var _known: null

    function _take(v: var): void {
        const known = {};
        for (const n of v.notifications || []) {
            known[n.id] = n.at;
            // The first record is what was there before the shell attached: nothing in it pops up.
            if (root._known !== null && root._known[n.id] !== n.at)
                root.arrived(n);
        }
        root._known = known;
        root._record = v;
    }

    // ── Commands ──────────────────────────────────────────────────────────────
    function _command(type: string, payload: var): void {
        if (!Yoke.attached)
            return;
        Yoke.link.command(unit, type, JSON.stringify(payload), null,
                          refusal => console.warn("notifications: " + type + " refused: " + refusal.code));
    }

    function dismiss(id: int): void { _command("notifications.dismiss", { "id": id }) }
    function dismissAll(app: string): void { _command("notifications.dismiss.all", app ? { "app": app } : {}) }
    // `action` is a key the notification offers; "default" is its own click.
    function invoke(id: int, action: string): void { _command("notifications.invoke", { "id": id, "action": action || "default" }) }
    function markSeen(): void {
        if (unseen > 0)
            _command("notifications.seen", {});
    }
    function setDnd(on: bool): void { _command("notifications.dnd.set", { "on": on }) }

    StreamJoin {
        id: join

        unit: root.unit
        stream: "notifications.list"
        onValue: v => root._take(v)
    }
}
