pragma ComponentBehavior: Bound

import QtQuick

import qs.themes

// SidePanelRight — slide-in panel on the right screen edge.
//
// Driven by PanelManager (panel id "side-right"); infrastructure in OverlayPanel.
//
//   BarChip {
//       panelId:        "side-right"
//       panelContentId: "main"
//       panelContent:   Component { MyPanel {} }
//   }
OverlayPanel {
    panelId: "side-right"
    edge:    "right"

    // With the bar drawn as tabs, the right tab grows this panel out of itself
    // (BarContainer); this window serves the strip shape alone.
    active: !(Theme.bar.shape === "tabs" && Theme.sidePanel.morph)

    panelWidth:    Theme.sizes.sidebarWidth
    panelColor:    Theme.sidePanel.background
    topLeftRadius:    Theme.sidePanel.radius
    bottomLeftRadius: Theme.sidePanel.radius
    contentMargin: Theme.sidePanel.padding

    dimOpacity: Theme.sidePanel.dimOpacity
    dimColor:   Theme.sidePanel.dimColor

    shadowEnabled: Theme.sidePanel.shadowEnabled
    shadowRadius:  Theme.sidePanel.shadowRadius
    shadowColor:   Theme.sidePanel.shadowColor
    shadowOffsetX: Theme.sidePanel.shadowOffsetX
    shadowOffsetY: Theme.sidePanel.shadowOffsetY
}
