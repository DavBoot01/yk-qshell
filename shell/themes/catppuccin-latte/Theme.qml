import QtQuick
import ".."

// Catppuccin Latte — light theme variant.
//
// Only values that differ from ThemeBase are listed; everything else is
// inherited (grouped-property override, see ThemeBase header).
ThemeBase {

    // ── Colors (Latte palette) ────────────────────────────────────────────────
    colors.background:         "#eff1f5"
    colors.surface:            "#ccd0da"
    colors.primary:            "#8839ef"
    colors.textBackground:     "#4c4f69"
    colors.textSurface:        "#4c4f69"
    colors.textSurfaceVariant: "#7c7f93"
    colors.outline:            "#acb0be"

    // ── Bar — white strip, violet accent ──────────────────────────────────────
    bar.stripBackground:       Qt.rgba(0.94, 0.95, 0.96, 0.85)
    bar.stripShadowColor:      Qt.rgba(0, 0, 0, 0.15)

    bar.pill.background:       Qt.rgba(1, 1, 1, 0.70)
    bar.pill.borderColor:      "#8839ef"
    bar.pill.shadowColor:      Qt.rgba(0, 0, 0, 0.20)

    bar.chip.defaultStyle:     "solid"
    bar.chip.background:       Qt.rgba(1, 1, 1, 0.80)
    bar.chip.borderColor:      "#8839ef"

    // ── Panels (light surfaces) ───────────────────────────────────────────────
    centerDropdown.background: Qt.rgba(0.94, 0.95, 0.96, 0.92)
    sidePanel.background:      Qt.rgba(0.94, 0.95, 0.96, 0.95)
    sidePanel.dimColor:        "#4c4f69"

    // ── Widget content — dark text on light background ────────────────────────
    widget.textColor:          "#4c4f69"
    widget.textColorDim:       "#7c7f93"
    widget.iconColor:          "#4c4f69"
    widget.subtleBackground:   Qt.rgba(0, 0, 0, 0.03)
    widget.hoverBackground:    Qt.rgba(0, 0, 0, 0.06)
    widget.activeBackground:   Qt.rgba(0, 0, 0, 0.10)
    widget.colorOk:            "#40a02b"
    widget.colorWarn:          "#df8e1d"
    widget.colorCritical:      "#d20f39"
}
