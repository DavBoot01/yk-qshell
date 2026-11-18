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
Shape {
    id: root

    property color fillColor:  "black"
    property real  radius:     12
    property real  flare:      12
    property bool  flareLeft:  true
    property bool  flareRight: true
    property bool  mirrored:   false

    readonly property real _fl: root.flareLeft  ? root.flare : 0
    readonly property real _fr: root.flareRight ? root.flare : 0
    // The corners never exceed what the body can hold.
    readonly property real _r: Math.max(0, Math.min(root.radius,
        (root.width - root._fl - root._fr) / 2, root.height - root.flare))

    preferredRendererType: Shape.CurveRenderer

    transform: Scale {
        origin.y: root.height / 2
        yScale:   root.mirrored ? -1 : 1
    }

    ShapePath {
        fillColor:   root.fillColor
        strokeWidth: -1

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
        PathLine { x: root.width - root._fr; y: root.height - root._r }

        // Bottom: convex corners.
        PathArc {
            x: root.width - root._fr - root._r; y: root.height
            radiusX: root._r; radiusY: root._r
            direction: PathArc.Clockwise
        }
        PathLine { x: root._fl + root._r; y: root.height }
        PathArc {
            x: root._fl; y: root.height - root._r
            radiusX: root._r; radiusY: root._r
            direction: PathArc.Clockwise
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
