import QtQuick

// Typed theme group — see ThemeBase for how groups compose.
// Override single values from a theme with grouped syntax, e.g. `colors.primary: "#fff"`.
QtObject {
    // Master switch. false = bar is always visible (default).
    property bool enabled: false
    // Height (px) of the invisible reveal zone at the screen edge.
    // The cursor must enter this zone to trigger the reveal when hidden.
    property int  hoverRegionHeight: 4
    // Reveal the bar when the Super (Meta/Win) key is held.
    property bool showOnSuper: true
    // Delay (ms) from Super press to bar reveal.
    // Prevents accidental reveal on quick launcher/WM shortcuts.
    property int  superShowDelay: 500
}
