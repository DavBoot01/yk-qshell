pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property string _assetsRoot: Qt.resolvedUrl("../assets/")

    function pathDistroLogo(distroId: string): string {
        console.log("[Assets] pathDistroLogo called with:", distroId)
        switch (distroId) {
            case "artix":
            case "arch":        return _assetsRoot + "distros/arch.svg"
            case "endeavouros": return _assetsRoot + "distros/endeavouros.svg"
            case "cachyos":     return _assetsRoot + "distros/cachyos.svg"
            case "nixos":       return _assetsRoot + "distros/nixos.svg"
            case "fedora":      return _assetsRoot + "distros/fedora.svg"
            case "linuxmint":   return _assetsRoot + "distros/mint.svg"
            case "ubuntu":
            case "zorin":
            case "popos":       return _assetsRoot + "distros/ubuntu.svg"
            case "debian":
            case "raspbian":
            case "kali":        return _assetsRoot + "distros/debian.svg"
            case "funtoo":
            case "gentoo":      return _assetsRoot + "distros/gentoo.svg"
            default:            return _assetsRoot + "distros/linux.svg"
        }
    }
}