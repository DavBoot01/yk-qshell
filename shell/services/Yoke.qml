pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Yoke.Interface

// The shell's one attachment to its application: the channel `shell` of the instance YOKE_INSTANCE names.
// Every service that reads the system goes through it. When the Core ends the attachment — a restart, an
// update — the binding attaches again once the channel's socket is back, and each service learns the
// present again from `attached`.
Singleton {
    id: root

    readonly property Attachment link: attachment
    readonly property bool attached: attachment.attached
    readonly property string instance: attachment.instance

    // A payload read as JSON; null, said once on the console, when it is not.
    function json(bytes): var {
        try {
            return JSON.parse(attachment.text(bytes));
        } catch (e) {
            console.warn("yoke: a payload is not JSON: " + e);
            return null;
        }
    }

    Attachment {
        id: attachment

        instance: Quickshell.env("YOKE_INSTANCE") ?? ""
        channel: Quickshell.env("YK_QSHELL_CHANNEL") || "shell"
        attachAgain: true

        onStatusChanged: {
            if (attached)
                console.info("yoke: attached to " + channel + " of " + instance + " (contract " + version + ")");
            else if (status === Attachment.Ended)
                console.warn("yoke: ended: " + failure.code + " " + failure.message);
        }
    }
}
