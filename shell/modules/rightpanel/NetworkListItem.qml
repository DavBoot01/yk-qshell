pragma ComponentBehavior: Bound

import QtQuick

import qs.themes
import qs.services

// NetworkListItem — single row in the WiFi network list.
//
// Props: ssid, signal (0-100), security ("WPA2"|"none"|...), active (bool)
// Emits: connectRequested(ssid) when connect button is clicked.
Item {
    id: root

    property string ssid:     ""
    property int    signal:   0
    property string security: "none"
    property bool   active:   false

    signal connectRequested(string ssid)

    implicitHeight: 44
    implicitWidth:  parent ? parent.width : 0

    // ── Background ────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: Theme.rounding.button
        color: root.active
            ? Qt.rgba(
                Theme.colors.primary.r,
                Theme.colors.primary.g,
                Theme.colors.primary.b, 0.12)
            : rowHover.containsMouse
                ? Theme.widget.hoverBackground
                : "transparent"

        Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
    }

    // ── Signal icon ───────────────────────────────────────────────────────────
    Text {
        id: signalIcon
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
        text:
            root.signal >= 75 ? "󰤨" :
            root.signal >= 50 ? "󰤥" :
            root.signal >= 25 ? "󰤢" :
                                "󰤟"
        color: root.active
            ? Theme.colors.primary
            : root.signal >= 50
                ? Theme.widget.textColorDim
                : Theme.widget.colorWarn
        font.family:    Theme.widget.fontFamily
        font.pixelSize: Theme.widget.fontSize

        Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
    }

    // ── SSID label ────────────────────────────────────────────────────────────
    Text {
        id: ssidLabel
        anchors {
            left: signalIcon.right; leftMargin: 8
            right: securityIcon.left; rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        text:           root.ssid
        color:          root.active ? Theme.colors.primary : Theme.widget.textColor
        font.family:    Theme.widget.fontFamily
        font.pixelSize: Theme.widget.fontSize
        font.bold:      root.active
        elide:          Text.ElideRight

        Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
    }

    // ── Security icon ─────────────────────────────────────────────────────────
    Text {
        id: securityIcon
        anchors { right: connectBtn.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        text:    root.security !== "none" && root.security !== "" ? "󰒃" : ""
        color:   Theme.widget.textColorDim
        font.family:    Theme.widget.fontFamily
        font.pixelSize: Theme.widget.fontSizeSmall
    }

    // ── Connect button / active indicator ────────────────────────────────────
    Item {
        id: connectBtn
        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
        width:  visible ? connectLabel.implicitWidth + 16 : 0
        height: 24
        visible: !root.active

        Rectangle {
            anchors.fill: parent
            radius: Theme.rounding.button
            color: btnHover.containsMouse
                ? Theme.widget.activeBackground
                : Theme.widget.hoverBackground

            Behavior on color { ColorAnimation { duration: Theme.animation.duration } }
        }

        Text {
            id: connectLabel
            anchors.centerIn: parent
            text:           WiFiService.connectingTo === root.ssid ? "…" : "Connect"
            color:          Theme.widget.textColor
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSizeSmall
        }

        MouseArea {
            id: btnHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            enabled:      WiFiService.connectingTo === ""
            onClicked:    root.connectRequested(root.ssid)
        }
    }

    // Connected checkmark
    Text {
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        visible: root.active
        text:    "󰄬"
        color:   Theme.colors.primary
        font.family:    Theme.widget.fontFamily
        font.pixelSize: Theme.widget.fontSize
    }

    // ── Hover for row ─────────────────────────────────────────────────────────
    MouseArea {
        id: rowHover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
