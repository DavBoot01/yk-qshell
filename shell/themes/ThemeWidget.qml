import QtQuick

// Typed theme group — see ThemeBase for how groups compose.
// Override single values from a theme with grouped syntax, e.g. `colors.primary: "#fff"`.
QtObject {
    // Primary text — main values (time, labels, titles)
    property color textColor:       "#cdd6f4"
    // Muted text — secondary values (seconds, date, captions)
    property color textColorDim:    "#a6adc8"
    // SVG icon tint — applied when LauncherButton.iconColor is active
    property color iconColor:       "#cdd6f4"
    // Interaction fills — translucent overlays that work on any panel colour.
    // subtleBackground: resting fill of list rows / cards
    // hoverBackground:  pointer over an interactive item
    // activeBackground: selected tab / open-panel chip / pressed row
    property color subtleBackground: Qt.rgba(1, 1, 1, 0.04)
    property color hoverBackground:  Qt.rgba(1, 1, 1, 0.06)
    property color activeBackground: Qt.rgba(1, 1, 1, 0.10)
    // Threshold colors — used by monitoring widgets (CPU, RAM, etc.)
    property color colorOk:       "#a6e3a1"   // healthy / connected
    property color colorWarn:     "#f9e2af"   // >70 %
    property color colorCritical: "#f38ba8"   // >90 %
    // Nerd Font required for icon glyphs in bar context
    property string fontFamily:    "JetBrainsMono Nerd Font"
    property int    fontSize:      13
    property int    fontSizeSmall: 11
    property int    fontSizeLarge: 15
}
