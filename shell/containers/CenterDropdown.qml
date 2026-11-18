pragma ComponentBehavior: Bound

import QtQuick

import qs.themes

// CenterDropdown — overlay panel that slides below the center pill.
//
// Activated by PanelManager.toggle("center-dropdown", contentId, content, screen),
// typically from a BarChip. Window lifecycle, content handling and dismissal live
// in OverlayPanel; this file only provides geometry and theme values.
OverlayPanel {
    panelId: "center-dropdown"
    edge:    "top"

    // Panel rests below the bar (strip + floating margins).
    topInset: Theme.sizes.barHeight
        + (Theme.bar.floating ? Theme.bar.floatingMargin * 2 : 0)

    panelWidth:  Theme.sizes.centerDropdownWidth
    panelHeight: Math.min(
        Math.round((screen ? screen.height : 800) / 4),
        Theme.sizes.centerDropdownMaxHeight
    )

    panelColor:        Theme.centerDropdown.background
    topLeftRadius:     Theme.centerDropdown.topLeftRadius
    topRightRadius:    Theme.centerDropdown.topRightRadius
    bottomLeftRadius:  Theme.centerDropdown.bottomLeftRadius
    bottomRightRadius: Theme.centerDropdown.bottomRightRadius
    contentMargin:     16

    shadowEnabled: Theme.centerDropdown.shadowEnabled
    shadowRadius:  Theme.centerDropdown.shadowRadius
    shadowColor:   Theme.centerDropdown.shadowColor
    shadowOffsetX: Theme.centerDropdown.shadowOffsetX
    shadowOffsetY: Theme.centerDropdown.shadowOffsetY
}
