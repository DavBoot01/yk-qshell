import QtQuick

// Typed theme group — see ThemeBase for how groups compose.
// Override single values from a theme with grouped syntax, e.g. `surface.sheen: 0.1`.
//
// The relief of the shell's surfaces — the bar's tabs and the panels — so they
// read as slightly domed rather than flat:
//   rim   — a thin light line along the edge, catching the light.
//   sheen — the surface's own colour lightened by this much at its top,
//           fading to the plain colour at its bottom.
// Both off by default (rim transparent, sheen 0): a flat surface.
QtObject {
    property color rimColor: "transparent"
    property real  rimWidth: 1
    property real  sheen:    0
}
