import ".."

// Default theme — translucent black, light orange for what is selected,
// white text. Everything not listed here is inherited from ThemeBase.
ThemeBase {

    // ── Selection — light orange ──────────────────────────────────────────────
    // Focused workspace, open-panel chip, selected tab, pressed row.
    colors.primary:          "#ffb870"
    widget.activeBackground: Qt.rgba(1.0, 0.72, 0.44, 0.45)

    // ── Bar — translucent black tabs ──────────────────────────────────────────
    bar.stripBackground:     Qt.rgba(0, 0, 0, 0.60)

    // ── Text — white ──────────────────────────────────────────────────────────
    colors.textBackground:     "#ffffff"
    colors.textSurface:        "#ffffff"
    colors.textSurfaceVariant: Qt.rgba(1, 1, 1, 0.70)
    widget.textColor:          "#ffffff"
    widget.textColorDim:       Qt.rgba(1, 1, 1, 0.70)
    widget.iconColor:          "#ffffff"

    // ── Text size — one step above ThemeBase ──────────────────────────────────
    widget.fontSize:      14
    widget.fontSizeSmall: 12
    widget.fontSizeLarge: 16
}
