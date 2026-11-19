pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes

// BarTab — the shape a bar pill sits in when the bar is drawn as tabs.
//
// A tab hangs from the screen edge: its bottom corners are rounded outwards
// (`radius`), and where it meets the edge it flares into it with inverse,
// concave corners (`flare`), so it reads as part of the screen's border rather
// than as a separate box.
//
//   ‾‾‾‾╲            ╱‾‾‾‾      ← flare (concave), on each side that has one
//        │  content  │
//        ╰───────────╯          ← radius (convex)
//
// A tab flush with a screen corner has no flare on that side (flareLeft /
// flareRight false): it runs straight into the corner.
//
// The item's width includes the flares; the body spans
// [flareLeft ? flare : 0, width - (flareRight ? flare : 0)].
// Drawn for a top bar; a bottom bar mirrors it (`mirrored`).
//
// ── Drop ──────────────────────────────────────────────────────────────────────
// A tab can grow a panel out of itself: `dropWidth × dropHeight` below the
// body — centred on it, or flush with its right or left side (`dropAlign`) —
// in the same outline, so the panel is the tab, with no seam, and the rim runs
// round both. On each side where the drop is wider than the body it meets the
// body with a concave corner (`dropFillet`) and turns down with a convex one
// (`dropTopRadius`); on a flush side the body's side runs straight down. Its
// free corners are `dropRadius`.
//
//   ‾‾‾╲            ╱‾‾‾
//       │  content  │
//   ╭───╯           ╰───╮      ← dropFillet (concave), dropTopRadius (convex)
//   │      panel        │
//   ╰───────────────────╯      ← dropRadius
//
// With dropHeight 0 the outline is the plain tab: the item is `bodyHeight`
// tall plus the drop, and the drop's free corners start from `radius`, so a
// container animating the drop from 0 morphs the tab without a jump.
//
// Relief (Theme.surface, through the properties below): the fill runs from
// `fillColor` lightened by `sheen` at the edge it hangs from to plain
// `fillColor` at its free edge, and a `rimWidth` line of `rimColor` follows
// the outline.
Shape {
    id: root

    property color fillColor:  "black"
    property real  radius:     12
    property real  flare:      12
    property bool  flareLeft:  true
    property bool  flareRight: true
    property bool  mirrored:   false
    property real  sheen:      0
    property color rimColor:   "transparent"
    property real  rimWidth:   1

    property real  bodyHeight:    height
    property real  dropWidth:     0
    property real  dropHeight:    0
    property real  dropRadius:    radius
    property real  dropTopRadius: radius
    property real  dropFillet:    flare
    // "center" | "right" | "left"
    property string dropAlign:    "center"

    readonly property real _fl: root.flareLeft  ? root.flare : 0
    readonly property real _fr: root.flareRight ? root.flare : 0
    readonly property real _h: root.bodyHeight
    // The corners never exceed what the body can hold.
    readonly property real _r: Math.max(0, Math.min(root.radius,
        (root.width - root._fl - root._fr) / 2, root._h - root.flare))

    // ── Drop geometry ─────────────────────────────────────────────────────────
    readonly property real _bl: root._fl
    readonly property real _br: root.width - root._fr
    readonly property real _dh: Math.max(0, root.dropHeight)
    readonly property real _dw: Math.max(root.dropWidth, root._br - root._bl)
    readonly property real _dl: root.dropAlign === "right" ? root._br - root._dw
                              : root.dropAlign === "left"  ? root._bl
                              : (root._bl + root._br - root._dw) / 2
    readonly property real _dr: root._dl + root._dw
    // Whether the drop reaches past the body, on each side.
    readonly property bool _wideL: root._bl - root._dl > 0.01 && root._dh > 0
    readonly property bool _wideR: root._dr - root._br > 0.01 && root._dh > 0
    readonly property real _fL: root._wideL
        ? Math.max(0, Math.min(root.dropFillet, (root._bl - root._dl) / 2, root._h - root._fl)) : 0
    readonly property real _fR: root._wideR
        ? Math.max(0, Math.min(root.dropFillet, (root._dr - root._br) / 2, root._h - root._fr)) : 0
    readonly property real _rtL: root._wideL
        ? Math.max(0, Math.min(root.dropTopRadius, root._bl - root._dl - root._fL, root._dh / 2)) : 0
    readonly property real _rtR: root._wideR
        ? Math.max(0, Math.min(root.dropTopRadius, root._dr - root._br - root._fR, root._dh / 2)) : 0
    // A side's room for the bottom corner: the drop's side alone where it is
    // wider, the body's side and the drop's where it runs straight down.
    readonly property real _rb: root._dh <= 0 ? root._r
        : Math.max(0, Math.min(root.dropRadius, root._dw / 2,
                               root._wideL ? root._dh - root._rtL : root._h + root._dh - root._fl,
                               root._wideR ? root._dh - root._rtR : root._h + root._dh - root._fr))
    readonly property real _yB: root._h + root._dh
    // Where the drop meets the body on each side: the body's bottom when the
    // drop is wider there; otherwise the side runs straight down and every
    // junction point is the start of the bottom corner.
    readonly property real _yJL: root._wideL ? root._h : root._yB - root._rb
    readonly property real _yJR: root._wideR ? root._h : root._yB - root._rb

    preferredRendererType: Shape.CurveRenderer

    transform: Scale {
        origin.y: root.height / 2
        yScale:   root.mirrored ? -1 : 1
    }

    ShapePath {
        strokeColor: root.rimColor
        strokeWidth: root.rimColor.a > 0 ? root.rimWidth : -1
        fillGradient: LinearGradient {
            x1: 0; y1: 0
            x2: 0; y2: root._h
            GradientStop {
                position: 0
                color: Qt.rgba(root.fillColor.r + (1 - root.fillColor.r) * root.sheen,
                               root.fillColor.g + (1 - root.fillColor.g) * root.sheen,
                               root.fillColor.b + (1 - root.fillColor.b) * root.sheen,
                               root.fillColor.a)
            }
            GradientStop { position: 1; color: root.fillColor }
        }

        startX: 0
        startY: 0

        // Along the edge.
        PathLine { x: root.width; y: 0 }

        // Right: concave flare into the body, or straight down a flush side.
        PathArc {
            x: root.width - root._fr; y: root._fr
            radiusX: root._fr; radiusY: root._fr
            direction: PathArc.Counterclockwise
        }
        // Down the body to the drop, a concave fillet out to its top, and its
        // convex top corner; all of it collapses to one point with no drop.
        PathLine { x: root._br; y: root._yJR - root._fR }
        PathArc {
            x: root._br + root._fR; y: root._yJR
            radiusX: root._fR; radiusY: root._fR
            direction: PathArc.Counterclockwise
        }
        PathLine { x: root._dr - root._rtR; y: root._yJR }
        PathArc {
            x: root._dr; y: root._yJR + root._rtR
            radiusX: root._rtR; radiusY: root._rtR
            direction: PathArc.Clockwise
        }
        PathLine { x: root._dr; y: root._yB - root._rb }

        // Bottom: convex corners.
        PathArc {
            x: root._dr - root._rb; y: root._yB
            radiusX: root._rb; radiusY: root._rb
            direction: PathArc.Clockwise
        }
        PathLine { x: root._dl + root._rb; y: root._yB }
        PathArc {
            x: root._dl; y: root._yB - root._rb
            radiusX: root._rb; radiusY: root._rb
            direction: PathArc.Clockwise
        }

        // Up the drop's side, its top corner, the fillet back into the body.
        PathLine { x: root._dl; y: root._yJL + root._rtL }
        PathArc {
            x: root._dl + root._rtL; y: root._yJL
            radiusX: root._rtL; radiusY: root._rtL
            direction: PathArc.Clockwise
        }
        PathLine { x: root._bl - root._fL; y: root._yJL }
        PathArc {
            x: root._bl; y: root._yJL - root._fL
            radiusX: root._fL; radiusY: root._fL
            direction: PathArc.Counterclockwise
        }

        // Left: up the body, then the concave flare back to the edge.
        PathLine { x: root._fl; y: root._fl }
        PathArc {
            x: 0; y: 0
            radiusX: root._fl; radiusY: root._fl
            direction: PathArc.Counterclockwise
        }
    }
}
