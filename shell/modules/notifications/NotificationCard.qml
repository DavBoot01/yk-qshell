pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.themes
import qs.services

// NotificationCard — one notification, as the popups and the right panel show it: the application's icon
// and name, when it came, its summary and body, its actions, and a close button.
//
// A click on the card answers it with its own action where it offers one; a button answers it with that
// action; × dismisses it. All go to the Plugin, which tells the application.
Item {
    id: card

    required property var notification
    // Where the card stands over the screen: a little more body, and a shadow of its own.
    property bool popup: false
    // The body's lines before it is cut.
    property int bodyLines: popup ? 3 : 2

    // Something was done with it: a popup leaves.
    signal acted()

    readonly property var n: notification
    readonly property bool critical: n.urgency === "critical"
    readonly property bool hovered: hover.hovered

    implicitHeight: content.implicitHeight + 24

    // The application's own picture, then its icon, then its desktop entry's, then a bell.
    readonly property string _iconSource: {
        const image = n.image || n.icon || "";
        if (image.startsWith("/"))
            return "file://" + image;
        if (image.startsWith("file://"))
            return image;
        for (const name of [n.icon, n.desktop_entry, n.app ? n.app.toLowerCase() : ""]) {
            if (!name || name.startsWith("/"))
                continue;
            const path = Quickshell.iconPath(name, true);
            if (path)
                return path;
        }
        return "";
    }

    function _ago(at: real): string {
        const s = Math.max(0, (DateTime.now - at) / 1000);
        if (s < 60)
            return Translation.tr("now");
        if (s < 3600)
            return Math.floor(s / 60) + " min";
        const d = new Date(at);
        const today = new Date(DateTime.now);
        return d.toDateString() === today.toDateString() ? Qt.formatTime(d, "HH:mm") : Qt.formatDate(d, "d MMM");
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: card.popup ? Theme.bar.tabBackground
             : card.hovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.045)
        border.width: card.critical ? 1.5 : (card.popup ? 1 : 0)
        border.color: card.critical ? Theme.colors.critical : Theme.surface.rimColor
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    HoverHandler { id: hover }

    TapHandler {
        enabled: card.n.default_action
        cursorShape: Qt.PointingHandCursor
        onTapped: {
            Notifications.invoke(card.n.id, "default");
            card.acted();
        }
    }

    Row {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 10

        // ── Icon ──────────────────────────────────────────────────────────────
        Item {
            width: 32; height: 32
            Image {
                id: icon
                anchors.fill: parent
                source: card._iconSource
                sourceSize: Qt.size(64, 64)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: !icon.visible
                text: card.critical ? "󰀦" : "󰂚"
                color: card.critical ? Theme.colors.critical : Theme.colors.primary
                font.family: Theme.widget.fontFamily
                font.pixelSize: 22
            }
        }

        Column {
            width: parent.width - 32 - parent.spacing
            spacing: 3

            // ── App · when · × ────────────────────────────────────────────────
            Item {
                width: parent.width
                height: 18
                Text {
                    anchors { left: parent.left; right: when.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    text: card.n.app || Translation.tr("Notification")
                    color: Theme.widget.textColorDim
                    elide: Text.ElideRight
                    font.family: Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSizeSmall
                }
                Text {
                    id: when
                    anchors { right: close.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    text: card._ago(card.n.at)
                    color: Theme.widget.textColorDim
                    font.family: Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSizeSmall - 1
                }
                Rectangle {
                    id: close
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: 20; height: 20; radius: 10
                    color: closeHover.hovered ? Theme.widget.hoverBackground : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: Theme.widget.textColorDim
                        font.family: Theme.widget.fontFamily
                        font.pixelSize: 12
                    }
                    HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            Notifications.dismiss(card.n.id);
                            card.acted();
                        }
                    }
                }
            }

            // ── Summary and body ──────────────────────────────────────────────
            Text {
                width: parent.width
                text: card.n.summary
                visible: text !== ""
                color: Theme.widget.textColor
                font.family: Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSize
                font.bold: true
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
            Text {
                width: parent.width
                text: card.n.body
                visible: text !== ""
                color: Theme.widget.textColorDim
                font.family: Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall
                wrapMode: Text.Wrap
                maximumLineCount: card.bodyLines
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            // ── Actions ───────────────────────────────────────────────────────
            Flow {
                width: parent.width
                spacing: 6
                topPadding: 4
                visible: card.n.actions.length > 0

                Repeater {
                    model: card.n.actions
                    Rectangle {
                        id: action
                        required property var modelData
                        width: label.implicitWidth + 20
                        height: 24
                        radius: 12
                        color: actionHover.hovered ? Qt.rgba(Theme.colors.primary.r, Theme.colors.primary.g, Theme.colors.primary.b, 0.28)
                                                   : Qt.rgba(Theme.colors.primary.r, Theme.colors.primary.g, Theme.colors.primary.b, 0.14)
                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: action.modelData.label
                            color: Theme.colors.primary
                            font.family: Theme.widget.fontFamily
                            font.pixelSize: Theme.widget.fontSizeSmall
                        }
                        HoverHandler { id: actionHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                Notifications.invoke(card.n.id, action.modelData.key);
                                card.acted();
                            }
                        }
                    }
                }
            }
        }
    }
}
