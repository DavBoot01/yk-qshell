import QtQuick

// Typed theme group — see ThemeBase for how groups compose.
// Override single values from a theme with grouped syntax, e.g. `colors.primary: "#fff"`.
QtObject {

    // ── Style mode ────────────────────────────────────────────────────
    // Same values as pill.defaultStyle.
    property string defaultStyle: "transparent"

    // ── Fill ──────────────────────────────────────────────────────────
    property color background: Qt.rgba(0.08, 0.04, 0.01, 0.72)
    property real backgroundOpacity: 1.0

    // ── Border ────────────────────────────────────────────────────────
    property color borderColor: "#fe8019"
    property real  borderWidth: 1

    // ── Shape ─────────────────────────────────────────────────────────
    // Smaller than the pill capsule — rounded-rect look inside the pill.
    property real radius: 7

    // ── Sizing ────────────────────────────────────────────────────────
    // Horizontal padding between content and chip edges.
    property real horizontalPadding: 6

    // ── Blur mode ─────────────────────────────────────────────────────
    property real blurRadius: 32
}
