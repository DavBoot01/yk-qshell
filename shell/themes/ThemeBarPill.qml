import QtQuick

// Typed theme group — see ThemeBase for how groups compose.
// Override single values from a theme with grouped syntax, e.g. `colors.primary: "#fff"`.
QtObject {

    // ── Style mode ────────────────────────────────────────────────────
    // "solid"      — filled Rectangle + border
    // "blur"       — low-opacity tint + layer.effect blur hint + border
    // "outline"    — transparent fill, border only
    // "transparent"— no fill, no border, content only (default)
    property string defaultStyle: "transparent"

    // ── Fill ──────────────────────────────────────────────────────────
    property color background: Qt.rgba(0.08, 0.04, 0.01, 0.60)
    property real backgroundOpacity: 1.0

    // ── Border ────────────────────────────────────────────────────────
    property color borderColor: "#fe8019"
    property real  borderWidth: 1

    // ── Shape ─────────────────────────────────────────────────────────
    property real radius: 14

    // ── Sizing ────────────────────────────────────────────────────────
    property real minWidth: 80
    property real verticalMargin: 8
    property real horizontalPadding: 14

    // ── Width animation ───────────────────────────────────────────────
    property int widthAnimationDuration: 200
    property var widthAnimationEasing:   Easing.OutCubic

    // ── Blur mode ─────────────────────────────────────────────────────
    property real blurRadius: 32

    // ── Shadow ────────────────────────────────────────────────────────
    property bool  shadowEnabled: false
    property real  shadowRadius:  10
    property color shadowColor:   Qt.rgba(0, 0, 0, 0.45)
    property real  shadowOffsetX: 0
    property real  shadowOffsetY: 3
}
