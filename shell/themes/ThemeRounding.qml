import QtQuick

// Typed theme group — see ThemeBase for how groups compose.
// Override single values from a theme with grouped syntax, e.g. `colors.primary: "#fff"`.
QtObject {
    // Panels, side drawers, large containers
    property real panel: 12
    // Cards and inner elements
    property real card: 8
    // Buttons and small controls
    property real button: 6
    // Screen-edge corners — typically 0 (flush to edge)
    property real screenEdge: 0
}
