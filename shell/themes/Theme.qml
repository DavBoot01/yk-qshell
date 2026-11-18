pragma Singleton
pragma ComponentBehavior: Bound

import "base"
import "catppuccin-latte" as Latte
import QtQuick
import Quickshell

// Theme — the single source of truth for all visual values in the shell.
//
// Every component accesses theme values through this singleton:
//   Theme.colors.primary
//   Theme.bar.pill.radius
//   Theme.animation.duration
//
// ── Switching themes ──────────────────────────────────────────────────────────
// Set `themeName` (at runtime, e.g. via `qs ipc call theme set catppuccin-latte`)
// or change its default below. Both built-in themes stay instantiated, so a
// switch is just a rebinding — every Theme.* binding updates live.
//
// ── Adding a theme ────────────────────────────────────────────────────────────
//   1. Create  themes/<name>/Theme.qml  — ThemeBase { colors.primary: ... }
//      (override single values with grouped syntax; the rest is inherited)
//   2. Create  themes/<name>/qmldir     — register the type
//   3. Add an import + an instance + an entry in `_themes` below.
//
// See themes/ThemeBase.qml and themes/ for the full property contract.
Singleton {
    id: root

    // ── Theme selection ───────────────────────────────────────────────────────
    property string themeName: "base"

    readonly property var names: Object.keys(root._themes)

    readonly property var _themes: ({
        "base":             _base,
        "catppuccin-latte": _latte
    })

    BaseTheme { id: _base }
    Latte.CatppuccinLatte { id: _latte }

    // Falls back to the default theme when the name is unknown.
    readonly property ThemeBase activeTheme: root._themes[root.themeName] ?? _base

    // ── Accessors ─────────────────────────────────────────────────────────────
    // All shell components bind to these properties.
    readonly property ThemeColors         colors:         activeTheme.colors
    readonly property ThemeRounding       rounding:       activeTheme.rounding
    readonly property ThemeBar            bar:            activeTheme.bar
    readonly property ThemeCenterDropdown centerDropdown: activeTheme.centerDropdown
    readonly property ThemeSidePanel      sidePanel:      activeTheme.sidePanel
    readonly property ThemeSurface        surface:        activeTheme.surface
    readonly property ThemeSizes          sizes:          activeTheme.sizes
    readonly property ThemeAnimation      animation:      activeTheme.animation
    readonly property ThemeFont           font:           activeTheme.font
    readonly property ThemeWidget         widget:         activeTheme.widget
}
