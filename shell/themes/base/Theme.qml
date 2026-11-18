import ".."

// Default theme — translucent black, light orange for what is selected,
// white text, on the bar and on every panel alike. Everything not listed here
// is inherited from ThemeBase.
ThemeBase {

    // ── Selection — light orange ──────────────────────────────────────────────
    // Focused workspace, open-panel chip, selected tab, pressed row.
    colors.primary:          "#ffb870"
    widget.activeBackground: Qt.rgba(1.0, 0.72, 0.44, 0.45)

    // ── Surfaces — translucent black, one density for the bar and the panels ──
    // Hyprland blurs the myshell:* layers behind it (see the README). Keep it
    // above the rule's ignore_alpha (0.45) and the side panel's dim below it,
    // so the panels are blurred and the dimmed screen is not.
    bar.stripBackground:       Qt.rgba(0, 0, 0, 0.72)
    centerDropdown.background: Qt.rgba(0, 0, 0, 0.72)
    sidePanel.background:      Qt.rgba(0, 0, 0, 0.72)

    // ── Neutrals — grey, not ThemeBase's blue-tinted ones ─────────────────────
    // outline: tracks, separators, idle dots and bars.
    colors.background: "#000000"
    colors.surface:    "#262626"
    colors.outline:    "#4d4d4d"

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
