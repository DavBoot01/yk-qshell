pragma ComponentBehavior: Bound

import QtQuick

import qs.themes

// SidePanelLeft — slide-in panel on the left screen edge.
//
// Driven by PanelManager (panel id "side-left"); infrastructure in OverlayPanel.
//
//   BarChip {
//       panelId:        "side-left"
//       panelContentId: "main"
//       panelContent:   Component { MyPanel {} }
//   }
OverlayPanel {
    panelId: "side-left"
    edge:    "left"

    panelWidth:    Theme.sizes.sidebarWidth
    panelColor:    Theme.sidePanel.background
    topRightRadius:    Theme.sidePanel.radius
    bottomRightRadius: Theme.sidePanel.radius
    contentMargin: Theme.sidePanel.padding

    dimOpacity: Theme.sidePanel.dimOpacity
    dimColor:   Theme.sidePanel.dimColor

    shadowEnabled: Theme.sidePanel.shadowEnabled
    shadowRadius:  Theme.sidePanel.shadowRadius
    shadowColor:   Theme.sidePanel.shadowColor
    shadowOffsetX: -Theme.sidePanel.shadowOffsetX
    shadowOffsetY: Theme.sidePanel.shadowOffsetY
}
