import QtQuick

// Typed theme group — see ThemeBase for how groups compose.
// Override single values from a theme with grouped syntax, e.g. `colors.primary: "#fff"`.
QtObject {

    // ── Background ────────────────────────────────────────────────────────
    // Overall bar strip tint — very low alpha so compositor blur dominates.
    property color stripBackground: Qt.rgba(0.12, 0.12, 0.18, 0.85)

    // ── Spacing ───────────────────────────────────────────────────────────
    // Gap between pill and the screen left/right edge
    property real horizontalMargin: 14
    // Spacing between sibling items inside a pill
    property real itemSpacing: 10

    // ── Floating mode ─────────────────────────────────────────────────────
    // When false (default): the strip fills the full window edge-to-edge.
    // When true: the strip floats inside the window with floatingMargin
    //   space on all sides, exposing rounded corners around the strip.
    property bool floating:       false
    // Gap between the window boundary and the strip when floating.
    // Must be >= stripShadowRadius + stripShadowOffsetY to avoid shadow clipping.
    property real floatingMargin: 8

    // ── Strip corner radii ────────────────────────────────────────────────
    // Requires Qt 6.7+ (Rectangle per-corner radius properties).
    // For a top bar flush to the screen edge, top corners are typically 0;
    // bottom corners get a visible radius.
    // When floating, set all four to the same value for a uniform rounded strip.
    property real stripRadiusTopLeft:     0
    property real stripRadiusTopRight:    0
    property real stripRadiusBottomLeft:  8
    property real stripRadiusBottomRight: 8

    // ── Strip shadow ──────────────────────────────────────────────────────
    // Rendered via QtQuick.Effects MultiEffect on the strip Rectangle.
    // Looks best with floating: true — when not floating the shadow may
    // clip at the window edges (increase floatingMargin to give it room).
    property bool  stripShadowEnabled:  false
    property real  stripShadowRadius:   12
    property color stripShadowColor:    Qt.rgba(0, 0, 0, 0.50)
    property real  stripShadowOffsetX:  0
    property real  stripShadowOffsetY:  4

    // ── Typography ────────────────────────────────────────────────────────
    // Must be a Nerd Font for icon glyphs to align correctly
    property string fontFamily: "JetBrainsMono Nerd Font"

    // ── Pill ──────────────────────────────────────────────────────────────
    // Outer pill: layout container only. Visual weight is near-zero by
    // default — individual items use BarChip for their own visual chrome.
    property ThemeBarPill pill: ThemeBarPill {}

    // ── Auto-hide ─────────────────────────────────────────────────────────
    // When enabled, the strip slides off-screen when idle and reveals on
    // hover or Super-key press.  Disabled by default (always visible).
    property ThemeBarAutoHide autoHide: ThemeBarAutoHide {}

    // ── Chip ──────────────────────────────────────────────────────────────
    // Per-item visual wrapper inside a pill. Each widget is individually
    // surrounded by a BarChip, giving it its own background and border.
    property ThemeBarChip chip: ThemeBarChip {}
}
