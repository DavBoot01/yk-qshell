pragma ComponentBehavior: Bound
import QtQuick

// ThemeBase — the contract every theme must implement.
//
// Extend this type in a new Theme.qml under themes/<name>/,
// overriding only the property groups you need to change.
//
// Every group is a typed object (themes/Theme*.qml) instantiated here with
// its defaults. A derived theme overrides INDIVIDUAL values with grouped
// property syntax — everything it does not mention is inherited:
//
//   ThemeBase {
//       colors.primary:        "#8839ef"
//       bar.pill.borderColor:  "#8839ef"
//   }
//
// Third-party theme quickstart:
//   1. Create  themes/<my-theme>/Theme.qml  extending ThemeBase
//   2. Add     themes/<my-theme>/qmldir     registering the type
//   3. In      themes/Theme.qml             import the new dir and swap activeTheme
QtObject {

    // ── Colors ────────────────────────────────────────────────────────────────
    property ThemeColors colors: ThemeColors {}

    // ── Corner radii ──────────────────────────────────────────────────────────
    property ThemeRounding rounding: ThemeRounding {}

    // ── Bar ───────────────────────────────────────────────────────────────────
    property ThemeBar bar: ThemeBar {}

    // ── Center dropdown ───────────────────────────────────────────────────────
    // Overlay panel that slides below the center pill.
    // Defaults mirror the bar strip so the dropdown looks like a natural
    // extension of the bar.  Override any property independently per theme.
    property ThemeCenterDropdown centerDropdown: ThemeCenterDropdown {}

    // ── Side panel ────────────────────────────────────────────────────────────
    // Right (and future left) slide-in panel.
    property ThemeSidePanel sidePanel: ThemeSidePanel {}

    // ── Layout sizes ──────────────────────────────────────────────────────────
    property ThemeSizes sizes: ThemeSizes {}

    // ── Animation ─────────────────────────────────────────────────────────────
    property ThemeAnimation animation: ThemeAnimation {}

    // ── Typography ────────────────────────────────────────────────────────────
    property ThemeFont font: ThemeFont {}

    // ── Widget content ────────────────────────────────────────────────────────
    // Visual properties for the content rendered inside bar chips and panels.
    // All widgets read exclusively from this group, so the complete widget
    // appearance can be overridden in one place per theme.
    property ThemeWidget widget: ThemeWidget {}
}
