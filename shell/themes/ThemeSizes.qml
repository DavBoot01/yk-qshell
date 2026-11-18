import QtQuick

// Typed theme group — see ThemeBase for how groups compose.
// Override single values from a theme with grouped syntax, e.g. `colors.primary: "#fff"`.
QtObject {
    // Total bar area height reserved at the screen edge.
    // Must equal bar.pill.verticalMargin * 2 + (pill height desired).
    // Used by side panels and dropdowns as their top offset.
    property real barHeight: 44
    property real sidebarWidth: 320
    property real bottomPanelHeight: 200
    property real centerDropdownWidth: 480
    property real centerDropdownMaxHeight: 400
    property real centerFloatingWidth: 560
    property real centerFloatingHeight: 420
}
