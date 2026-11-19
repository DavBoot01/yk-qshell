pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes

// SideDock — the right tab and the right panel in one outline, the panel
// growing out of the tab's outer bottom corner.
//
// The tab's body is [bodyLeft, bodyRight] × [0, bodyHeight] in the item's
// coordinates (the bar strip's). The panel hangs below it, flush with the
// body's right side: `panelWidth` wide, `panelHeight` tall. A container grows
// both from the corner — width from the tab's `radius`, height from 0 — so at
// rest the outline is the plain tab, its outer bottom corner being the panel's.
//
// Where the panel meets the tab's bottom on the left:
//   narrower   a concave corner (`fillet`) turns the tab's bottom down into the
//              panel's side, and the tab keeps its convex corner further left;
//   as wide    the sides run straight down;
//   wider      the panel turns up with a convex corner (`cornerRadius`) and a
//              concave one (`fillet`) joins it to the tab's side.
// The three pass into one another as the width grows.
//
// The panel's corners are `cornerRadius`, within what its size holds. The tab's
// top corners are flares into the screen's edge (`leftFlare`, `rightFlare`) or
// convex corners (`topCorner`) — never both — so the open panel can read as
// one card rounded alike all round.
//
//   ‾‾‾╲          ╱‾‾‾         ╭──────────╮
//       │  tab   │        →    │   tab    │
//       ╰──╮     │         ╭───╯          │
//          │panel│         │    panel     │
//          ╰─────╯         ╰──────────────╯
Shape {
    id: root

    property color fillColor:  "black"
    property real  sheen:      0
    property color rimColor:   "transparent"
    property real  rimWidth:   1

    property real  bodyHeight:  40
    property real  bodyLeft:    0
    property real  bodyRight:   0
    property real  radius:      12
    property real  leftFlare:   12
    property real  rightFlare:  12
    property real  topCorner:   0
    property real  panelWidth:  12
    property real  panelHeight: 0
    property real  cornerRadius: 12
    property real  fillet:      12

    readonly property real _h:  root.bodyHeight
    readonly property real _bl: root.bodyLeft
    readonly property real _br: root.bodyRight
    readonly property real _pw: Math.max(0, root.panelWidth)
    readonly property real _ph: Math.max(0, root.panelHeight)
    readonly property real _dl: root._br - root._pw
    readonly property real _yB: root._h + root._ph

    // The top corners: a flare or a convex corner, never both.
    readonly property real _flL: root.topCorner > 0 ? 0 : root.leftFlare
    readonly property real _flR: root.topCorner > 0 ? 0 : root.rightFlare
    readonly property real _tc:  Math.max(0, Math.min(root.topCorner, root._h / 2))

    // How far the panel reaches past the tab's left side (negative: short of it).
    readonly property real _d:   root._bl - root._dl
    readonly property bool _wide:   root._d > 0.01
    readonly property bool _narrow: root._d < -0.01
    readonly property real _f:  Math.max(0, Math.min(root.fillet, Math.abs(root._d) / 2,
                                                     root._narrow ? root._ph / 2 : root._h - root._flL - root._tc))
    readonly property real _fW: root._wide ? root._f : 0
    readonly property real _fN: root._narrow ? root._f : 0
    // The panel's top-left corner where it is wider; the tab's bottom-left
    // where it is narrower.
    readonly property real _rtW: root._wide
        ? Math.max(0, Math.min(root.cornerRadius, root._d - root._f, root._ph / 2)) : 0
    readonly property real _rtN: root._narrow
        ? Math.max(0, Math.min(root.radius, -root._d - root._f, root._h - root._flL - root._tc)) : 0

    // The panel's bottom corners. The right one is the tab's outer corner at
    // rest, so it has the tab's side above it as well as the panel's.
    readonly property real _rbR: Math.max(0, Math.min(root.cornerRadius, root._pw,
                                                      root._yB - root._flR - root._tc))
    readonly property real _rbL: Math.max(0, Math.min(root.cornerRadius, root._pw - root._rbR,
                                                      root._ph - root._rtW - root._fN))

    preferredRendererType: Shape.CurveRenderer

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

        startX: root._bl - root._flL + root._tc
        startY: 0

        // Along the edge; the right top corner — a flare or a convex corner,
        // one of the two arcs always a point.
        PathLine { x: root._br + root._flR - root._tc; y: 0 }
        PathArc {
            x: root._br - root._tc; y: root._flR
            radiusX: root._flR; radiusY: root._flR
            direction: PathArc.Counterclockwise
        }
        PathArc {
            x: root._br; y: root._flR + root._tc
            radiusX: root._tc; radiusY: root._tc
            direction: PathArc.Clockwise
        }

        // Down the right side, tab and panel as one, round the bottom.
        PathLine { x: root._br; y: root._yB - root._rbR }
        PathArc {
            x: root._br - root._rbR; y: root._yB
            radiusX: root._rbR; radiusY: root._rbR
            direction: PathArc.Clockwise
        }
        PathLine { x: root._dl + root._rbL; y: root._yB }
        PathArc {
            x: root._dl; y: root._yB - root._rbL
            radiusX: root._rbL; radiusY: root._rbL
            direction: PathArc.Clockwise
        }

        // Up the panel's left side to the tab. Wider: its convex top corner,
        // then the fillet up into the tab's side. Narrower: the fillet out onto
        // the tab's bottom, then the tab's own corner. Each arc is a point
        // where it does not apply.
        PathLine { x: root._dl; y: root._h + root._rtW + root._fN }
        PathArc {
            x: root._dl + root._rtW; y: root._h + root._fN
            radiusX: root._rtW; radiusY: root._rtW
            direction: PathArc.Clockwise
        }
        PathArc {
            x: root._dl + root._rtW - root._fN; y: root._h
            radiusX: root._fN; radiusY: root._fN
            direction: PathArc.Counterclockwise
        }
        PathLine { x: root._bl - root._fW + root._rtN; y: root._h }
        PathArc {
            x: root._bl - root._fW; y: root._h - root._rtN
            radiusX: root._rtN; radiusY: root._rtN
            direction: PathArc.Clockwise
        }
        PathArc {
            x: root._bl; y: root._h - root._rtN - root._fW
            radiusX: root._fW; radiusY: root._fW
            direction: PathArc.Counterclockwise
        }

        // Up the tab's left side and its top corner back to the edge.
        PathLine { x: root._bl; y: root._flL + root._tc }
        PathArc {
            x: root._bl + root._tc; y: root._flL
            radiusX: root._tc; radiusY: root._tc
            direction: PathArc.Clockwise
        }
        PathArc {
            x: root._bl - root._flL + root._tc; y: 0
            radiusX: root._flL; radiusY: root._flL
            direction: PathArc.Counterclockwise
        }
    }
}
