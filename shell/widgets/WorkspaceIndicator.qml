pragma ComponentBehavior: Bound

import QtQuick

import qs.themes

// Workspace dot indicator — presentational; bind `workspaces` from Workspace.states.
//
// ── Visual states ─────────────────────────────────────────────────────────────
//   focused   — wide pill, accent color, full opacity
//   occupied  — round dot, surface color, mid opacity  (has windows)
//   empty     — round dot, surface color, low opacity
//
// ── Interactions ──────────────────────────────────────────────────────────────
//   Left click  → goTo(id)
//   Right click → moveWindowTo(id)  (move active window here)
Item {
    id: root

    // [{ id, focused, occupied }]
    property var workspaces: []

    signal goTo(int id)
    signal moveWindowTo(int id)

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 5
        anchors.centerIn: parent

        Repeater {
            model: root.workspaces

            delegate: Item {
                required property var modelData   // { id, focused, occupied }

                readonly property bool focused:  modelData.focused
                readonly property bool occupied: modelData.occupied

                // Dot dimensions
                readonly property real dotW: focused ? 20 : 8
                readonly property real dotH: 8

                implicitWidth:  dotW
                implicitHeight: dotH

                Rectangle {
                    anchors.centerIn: parent
                    width:  parent.dotW
                    height: parent.dotH
                    radius: parent.dotH / 2

                    color: parent.focused
                        ? Theme.colors.primary
                        : dotMouse.containsMouse
                            ? Theme.widget.hoverBackground
                            : Theme.colors.outline

                    opacity: parent.focused  ? 1.0
                           : parent.occupied ? 0.75
                           :                   0.30

                    Behavior on width {
                        NumberAnimation {
                            duration:    Theme.animation.duration
                            easing.type: Theme.animation.curve
                        }
                    }
                    Behavior on color   { ColorAnimation  { duration: Theme.animation.duration } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animation.duration } }
                }

                MouseArea {
                    id: dotMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: event => {
                        if (event.button === Qt.RightButton)
                            root.moveWindowTo(parent.modelData.id)
                        else
                            root.goTo(parent.modelData.id)
                    }
                }
            }
        }
    }
}
