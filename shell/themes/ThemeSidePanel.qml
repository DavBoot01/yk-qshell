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
}
