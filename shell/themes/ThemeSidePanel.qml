import QtQuick

// Typed theme group — see ThemeBase for how groups compose.
// Override single values from a theme with grouped syntax, e.g. `colors.primary: "#fff"`.
QtObject {
    property color background:    Qt.rgba(0.09, 0.09, 0.14, 0.95)
    // Left/top rounded corners (the edge that faces the screen interior)
    property real  radius:        12
    property real  padding:       16
    // Dim overlay covering the screen behind the panel
    property real  dimOpacity:    0.40
    property color dimColor:      "#000000"
    // Drop shadow on the inner edge
    property bool  shadowEnabled: false
    property real  shadowRadius:  20
    property color shadowColor:   Qt.rgba(0, 0, 0, 0.60)
    property real  shadowOffsetX: -6
    property real  shadowOffsetY: 0

    // Morph (bar shape "tabs", top bar): the right panel grows out of the
    // right tab's outer bottom corner, as if the bar burst open there — in one
    // outline with the tab (SideDock), flush with its right side, standing off
    // the screen's side and bottom as the tab does, at least as wide as the
    // tab. While it grows the tab's flares give way to convex corners, so the
    // open panel is one card rounded alike all round. Its content comes in
    // last, drifting out of the corner by `contentDrift`. Closing runs it
    // backwards.
    property bool morph:          true
    // Its height, as a share of the screen's.
    property real heightFraction: 0.60
    // Every corner of the open panel.
    property real cornerRadius:   28
    property int  openDuration:   700
    property int  closeDuration:  500
    // The width grows ahead of the height, so a panel as wide as the tab
    // meets its side before the height has settled.
    property var  widthStage:     [0.00, 0.55]
    property var  growStage:      [0.00, 0.80]
    property var  cornersStage:   [0.15, 0.85]
    property var  contentStage:   [0.45, 1.00]
    property real contentDrift:   14
}
