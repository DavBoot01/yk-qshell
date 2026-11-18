import QtQuick

// Typed theme group — see ThemeBase for how groups compose.
// Override single values from a theme with grouped syntax, e.g. `colors.primary: "#fff"`.
QtObject {
    // Standard transition duration in milliseconds
    property int duration: 200
    property var curve: Easing.OutCubic
    // Slower transition for larger, more elaborate motions
    property int durationLong: 350
    property var curveLong: Easing.OutExpo
}
