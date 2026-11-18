pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.services

// yk-qshell: a desktop shell whose view of the system comes from a Yoke application. This first bar shows
// what hw-monitor says of the CPU and the memory; the rest of the shell is ported from my-qshell piece by
// piece, each service that reads the system moving onto a Plugin of the application.
ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 30
            color: "#1e1e2e"

            Row {
                anchors.centerIn: parent
                spacing: 18

                Text {
                    color: Yoke.attached ? "#a6e3a1" : "#f38ba8"
                    font.pixelSize: 13
                    text: Yoke.attached ? "yoke" : "yoke: not attached"
                }
                Text {
                    color: "#cdd6f4"
                    font.pixelSize: 13
                    text: SystemStats.ready ? "CPU " + SystemStats.cpuTotal + "%" : "CPU …"
                }
                Text {
                    color: "#cdd6f4"
                    font.pixelSize: 13
                    text: SystemStats.ready ? "RAM " + SystemStats.ramUsedPercent + "% of "
                          + (SystemStats.ramTotalMiB / 1024).toFixed(1) + " GiB" : "RAM …"
                }
                Text {
                    color: "#9399b2"
                    font.pixelSize: 13
                    text: SystemStats.coreCount > 0 ? SystemStats.coreCount + " cores" : ""
                }
            }
        }
    }
}
