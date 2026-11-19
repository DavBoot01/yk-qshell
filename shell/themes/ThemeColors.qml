import QtQuick

// Typed theme group — see ThemeBase for how groups compose.
// Override single values from a theme with grouped syntax, e.g. `colors.primary: "#fff"`.
QtObject {
    // Panel and window background
    property color background: "#1e1e2e"
    // Elevated surfaces: cards, dropdowns, popups
    property color surface: "#313244"
    // Primary accent color
    property color primary: "#cba6f7"
    // Body text rendered on a background surface
    property color textBackground: "#cdd6f4"
    // Body text rendered on an elevated surface
    property color textSurface: "#cdd6f4"
    // Muted / secondary / caption text
    property color textSurfaceVariant: "#a6adc8"
    // Borders and dividers
    property color outline: "#45475a"
    // What asks for attention now: a critical notification
    property color critical: "#f38ba8"
}
