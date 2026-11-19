pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs
import qs.themes
import qs.widgets
import qs.services
import qs.containers
import qs.modules.center
import qs.modules.rightpanel
import qs.functions

// Bar — three floating pill islands, content only.
// Window infrastructure (PanelWindows, pill chrome, per-screen Variants)
// is handled by BarContainer in containers/.
//
// ── Carousel panel ────────────────────────────────────────────────────────────
// All center-pill chips that open the CenterDropdown share a SINGLE Component
// instance (_carouselContent).  This is critical: Loader.sourceComponent
// compares object references — reusing the same instance means the carousel
// survives page switches without being destroyed and recreated.
//
// With pragma ComponentBehavior: Bound, Component{} blocks defined here can
// reference the `bar` id, so `bar._carouselContent` is accessible from every
// content Component child.
//
// ── IPC ───────────────────────────────────────────────────────────────────────
// Panels can be toggled from the compositor (opens on the first screen):
//   qs ipc call panels toggle <clock|system|sensors|network|audio|wifi|bluetooth>
//   qs ipc call panels close
BarContainer {
    id: bar
    position: "top"

    // Shared carousel Component — one instance, referenced by all panel chips.
    property Component _carouselContent: Component { CenterCarousel {} }

    // Shared right-panel Component — audio and wifi chips open the same tab host.
    property Component _rightPanelContent: Component { RightPanel {} }

    IpcHandler {
        target: "panels"

        function toggle(name: string): void {
            const screen = Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
            switch (name) {
            case "clock":
            case "system":
            case "sensors":
            case "network":
                PanelManager.toggle("center-dropdown", name, bar._carouselContent, screen)
                break
            case "audio":
            case "wifi":
            case "bluetooth":
                PanelManager.toggle("side-right", name, bar._rightPanelContent, screen)
                break
            default:
                console.warn("[Bar] Unknown panel:", name)
            }
        }

        function close(): void { PanelManager.close() }
    }

    // ── Left pill: app launcher + workspaces ─────────────────────────────────────
    leftContent: Component {
        Row {
            spacing: Theme.bar.itemSpacing

            BarChip {
                anchors.verticalCenter: parent.verticalCenter
                content: Component {
                    LauncherButton {
                        iconSource:  AssetUtils.pathDistroLogo(SystemInfo.distroId)
                        onActivated: AppLauncher.launch()
                    }
                }
            }

            BarChip {
                anchors.verticalCenter: parent.verticalCenter
                content: Component {
                    WorkspaceIndicator {
                        workspaces:       Workspace.states
                        onGoTo:           id => Workspace.goTo(id)
                        onMoveWindowTo:   id => Workspace.moveWindowTo(id)
                    }
                }
            }
        }
    }

    // ── Center pill: cpu · ram · sensors · network ───────────────────────────────
    centerContent: Component {
        Row {
            spacing: Theme.bar.itemSpacing

            // CPU — opens carousel at "system" page
            BarChip {
                anchors.verticalCenter: parent.verticalCenter
                panelId:        "center-dropdown"
                panelContentId: "system"
                panelContent:   bar._carouselContent
                content: Component {
                    CpuWidget {
                        totalPercent: SystemStats.cpuTotal
                        corePercents: SystemStats.cpuCores
                    }
                }
            }

            // RAM — also opens "system" page (both CPU and RAM chips highlight together)
            BarChip {
                anchors.verticalCenter: parent.verticalCenter
                panelId:        "center-dropdown"
                panelContentId: "system"
                panelContent:   bar._carouselContent
                content: Component {
                    RamWidget {
                        usedPercent: SystemStats.ramUsedPercent
                        usedMiB:     SystemStats.ramUsedMiB
                        totalMiB:    SystemStats.ramTotalMiB
                    }
                }
            }

            // Sensors — the CPU's temperature and every other one; opens carousel at "sensors" page
            BarChip {
                anchors.verticalCenter: parent.verticalCenter
                visible: Sensors.present
                panelId:        "center-dropdown"
                panelContentId: "sensors"
                panelContent:   bar._carouselContent
                content: Component {
                    SensorsWidget {
                        celsius:      Sensors.cpuCelsius
                        level:        Sensors.level
                        temperatures: Sensors.temperatures
                    }
                }
            }

            // Network — opens carousel at "network" page
            BarChip {
                anchors.verticalCenter: parent.verticalCenter
                panelId:        "center-dropdown"
                panelContentId: "network"
                panelContent:   bar._carouselContent
                content: Component {
                    NetworkWidget {
                        connected:     Network.connected
                        type:          Network.type
                        ssid:          Network.ssid
                        wifiSignal:    Network.wifiSignal
                        rxBytesPerSec: Network.rxBytesPerSec
                        txBytesPerSec: Network.txBytesPerSec
                    }
                }
            }
        }
    }

    // ── Right pill: audio · wifi · bluetooth · battery · clock · tray ────────────
    rightContent: Component {
        Row {
            id: rightRow
            spacing: Theme.bar.itemSpacing

            // Audio chip — toggles the right panel on the audio tab
            BarChip {
                anchors.verticalCenter: parent.verticalCenter
                panelId:        "side-right"
                panelContentId: "audio"
                panelContent:   bar._rightPanelContent
                content: Component {
                    AudioWidget {
                        volume:     AudioService.volume
                        muted:      AudioService.muted
                        outputForm: AudioService.outputForm
                        hasInput:   AudioService.hasInput
                        inputMuted: AudioService.inputMuted
                        onStepped:  steps => AudioService.stepVolume(steps)
                    }
                }
            }

            // WiFi chip — toggles the right panel on the wifi tab
            BarChip {
                anchors.verticalCenter: parent.verticalCenter
                panelId:        "side-right"
                panelContentId: "wifi"
                panelContent:   bar._rightPanelContent
                content: Component {
                    WiFiWidget {
                        connected:  Network.connected
                        type:       Network.type
                        ssid:       Network.ssid
                        wifiSignal: Network.wifiSignal
                    }
                }
            }

            // Bluetooth chip — toggles the right panel on the bluetooth tab
            BarChip {
                anchors.verticalCenter: parent.verticalCenter
                visible:        BluetoothService.available
                panelId:        "side-right"
                panelContentId: "bluetooth"
                panelContent:   bar._rightPanelContent
                content: Component {
                    BluetoothWidget {
                        available: BluetoothService.available
                        powered:   BluetoothService.powered
                        connected: BluetoothService.connected.length
                        asking:    BluetoothService.pairing !== null
                    }
                }
            }

            BarChip {
                anchors.verticalCenter: parent.verticalCenter
                content: Component {
                    BatteryIndicator {
                        present:     Battery.present
                        percent:     Battery.percent
                        charging:    Battery.charging
                        full:        Battery.full
                        powerNow:    Battery.powerNow
                        timeToFull:  Battery.timeToFull
                        timeToEmpty: Battery.timeToEmpty
                    }
                }
            }

            // Clock — opens the carousel at its "clock" page
            BarChip {
                anchors.verticalCenter: parent.verticalCenter
                panelId:        "center-dropdown"
                panelContentId: "clock"
                panelContent:   bar._carouselContent
                content: Component {
                    DateTimeView {
                        hours:   DateTime.hours
                        minutes: DateTime.minutes
                        seconds: DateTime.seconds
                        date:    DateTime.date
                    }
                }
            }

            // Tray — at the right end
            BarChip {
                anchors.verticalCenter: parent.verticalCenter
                content: Component {
                    TrayBar { model: TrayService.items }
                }
            }
        }
    }
}
