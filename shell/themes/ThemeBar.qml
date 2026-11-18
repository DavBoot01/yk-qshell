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

    // ── Shape ─────────────────────────────────────────────────────────────
    // "tabs"  (default): no continuous strip; each pill sits in a tab that
    //         hangs from the screen edge and flares into it with concave
    //         corners (BarTab). Between the tabs the screen shows through.
    //         The space is still reserved, and `floating` is ignored.
    // "strip": one continuous strip across the edge (stripBackground,
    //          stripRadius*, floating).
    property string shape: "tabs"
    // Tab fill — the strip's, so a theme colours both shapes at once.
    property color tabBackground: stripBackground
    // Convex radius of a tab's two free corners.
    property real  tabRadius:     14
    // Radius of the concave corners where a tab meets the edge.
    property real  tabFlare:      14
    // Extra room between a pill and its tab, on each side.
    property real  tabPadding:    0
    // true: the left and right tabs run into the screen corners (no flare there).
    // false: they stand off the corners and flare on both sides, like the center.
    property bool  tabFlushEdges: false
    // When not flush: gap between the screen's side and where a side tab's
    // flare starts.
    property real  tabEdgeMargin: 16

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
