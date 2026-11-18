pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic as QC

import qs.themes
import qs.services

// BluetoothPanel — the adapter, a pairing waiting for the person, the paired devices and those in range.
//
// Everything comes from BluetoothService; while this tab is open the adapter discovers.
Item {
    id: root

    implicitWidth:  parent ? parent.width  : 0
    implicitHeight: parent ? parent.height : 0

    // ── Header: the adapter and its power ─────────────────────────────────────
    Row {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 32
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - power.width - parent.spacing
            text: !BluetoothService.available ? "󰂲  " + Translation.tr("No adapter")
                : BluetoothService.powered ? "󰂯  " + Translation.tr("Bluetooth on")
                : "󰂲  " + Translation.tr("Bluetooth off")
            color: BluetoothService.powered ? Theme.widget.textColor : Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSize
            elide: Text.ElideRight
        }

        Rectangle {
            id: power
            visible: BluetoothService.available
            width: 70; height: 28
            anchors.verticalCenter: parent.verticalCenter
            radius: Theme.rounding.button
            color: powerHover.containsMouse ? Theme.widget.activeBackground : Theme.widget.hoverBackground
            Text {
                anchors.centerIn: parent
                text: BluetoothService.powered ? Translation.tr("Turn off") : Translation.tr("Turn on")
                color: Theme.widget.textColor
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall
            }
            MouseArea {
                id: powerHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: BluetoothService.setPowered(!BluetoothService.powered)
            }
        }
    }

    // ── A pairing waiting for the person ──────────────────────────────────────
    Rectangle {
        id: pairingCard
        readonly property var p: BluetoothService.pairing
        readonly property bool needsCode: p !== null && (p.kind === "pin" || p.kind === "passkey")
        anchors { top: header.bottom; left: parent.left; right: parent.right }
        anchors.topMargin: 6
        visible: p !== null
        height: visible ? pairingColumn.implicitHeight + 16 : 0
        radius: Theme.rounding.button
        color: Qt.rgba(Theme.widget.colorWarn.r, Theme.widget.colorWarn.g, Theme.widget.colorWarn.b, 0.15)

        Column {
            id: pairingColumn
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
            spacing: 6

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                readonly property var p: pairingCard.p
                text: !p ? ""
                    : (p.alias || p.address) + ": "
                      + (p.kind === "confirm" ? Translation.tr("does the code match?") + " " + p.passkey
                       : p.kind === "pin" ? Translation.tr("enter the PIN")
                       : p.kind === "passkey" ? Translation.tr("enter the passkey")
                       : p.kind === "display-passkey" || p.kind === "display-pin"
                         ? Translation.tr("type this code on the device:") + " " + (p.passkey ?? p.pin)
                       : Translation.tr("allow the connection?"))
                color: Theme.widget.textColor
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSize
            }

            Rectangle {
                visible: pairingCard.needsCode
                width: parent.width; height: 28
                radius: Theme.rounding.button
                color: Theme.widget.subtleBackground
                TextInput {
                    id: code
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.widget.textColor
                    font.family:    Theme.widget.fontFamily
                    font.pixelSize: Theme.widget.fontSize
                    inputMethodHints: pairingCard.p && pairingCard.p.kind === "passkey" ? Qt.ImhDigitsOnly : Qt.ImhNone
                    onAccepted: { BluetoothService.answerPairing(true, text); text = ""; }
                }
            }

            Row {
                visible: pairingCard.p !== null && pairingCard.p.answers
                spacing: 6
                Repeater {
                    model: [ { "label": "Accept", "accept": true }, { "label": "Reject", "accept": false } ]
                    delegate: Rectangle {
                        required property var modelData
                        width: 86; height: 26
                        radius: Theme.rounding.button
                        color: answerHover.containsMouse ? Theme.widget.activeBackground : Theme.widget.hoverBackground
                        Text {
                            anchors.centerIn: parent
                            text: Translation.tr(parent.modelData.label)
                            color: Theme.widget.textColor
                            font.family:    Theme.widget.fontFamily
                            font.pixelSize: Theme.widget.fontSizeSmall
                        }
                        MouseArea {
                            id: answerHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { BluetoothService.answerPairing(parent.modelData.accept, code.text); code.text = ""; }
                        }
                    }
                }
            }
        }
    }

    // ── Error banner ──────────────────────────────────────────────────────────
    Rectangle {
        id: errorBanner
        anchors { top: pairingCard.bottom; left: parent.left; right: parent.right }
        anchors.topMargin: 6
        visible: BluetoothService.lastError !== ""
        height: visible ? 30 : 0
        radius: Theme.rounding.button
        color: Qt.rgba(Theme.widget.colorCritical.r, Theme.widget.colorCritical.g, Theme.widget.colorCritical.b, 0.15)
        Text {
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            width: parent.width - 16
            text: "󰀨  " + BluetoothService.lastError
            color: Theme.widget.colorCritical
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSizeSmall
            elide: Text.ElideRight
        }
    }

    // ── The devices ───────────────────────────────────────────────────────────
    QC.ScrollView {
        anchors { top: errorBanner.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        anchors.topMargin: 6
        clip: true
        QC.ScrollBar.vertical.policy: QC.ScrollBar.AsNeeded
        QC.ScrollBar.horizontal.policy: QC.ScrollBar.AlwaysOff

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: BluetoothService.powered ? BluetoothService.devices : []
                delegate: BluetoothListItem {
                    required property var modelData
                    width:     parent ? parent.width : 0
                    alias:     modelData.alias
                    icon:      modelData.icon ?? ""
                    connected: modelData.connected
                    paired:    true
                    battery:   modelData.battery ?? -1
                    busy:      BluetoothService.busy === modelData.address
                    onActivated: modelData.connected ? BluetoothService.disconnect(modelData.address)
                                                     : BluetoothService.connect(modelData.address)
                    onForgetRequested: BluetoothService.forget(modelData.address)
                }
            }

            Text {
                visible: BluetoothService.powered && BluetoothService.discovered.length > 0
                width: parent.width
                text: Translation.tr("In range")
                color: Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSizeSmall
                topPadding: 10
                bottomPadding: 4
            }

            Repeater {
                model: BluetoothService.powered ? BluetoothService.discovered : []
                delegate: BluetoothListItem {
                    required property var modelData
                    width:   parent ? parent.width : 0
                    alias:   modelData.alias
                    icon:    modelData.icon ?? ""
                    paired:  false
                    busy:    BluetoothService.busy === modelData.address
                    onActivated: BluetoothService.pair(modelData.address)
                }
            }

            Text {
                visible: BluetoothService.powered && BluetoothService.devices.length === 0
                         && BluetoothService.discovered.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Translation.tr("Looking for devices…")
                color: Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: Theme.widget.fontSize
                topPadding: 20
            }
        }
    }
}
