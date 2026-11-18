import QtQuick

// Typed theme group — see ThemeBase for how groups compose.
// Override single values from a theme with grouped syntax, e.g. `colors.primary: "#fff"`.
QtObject {
    // Fill — mirrors bar.stripBackground
    property color background: Qt.rgba(0.12, 0.12, 0.18, 0.90)

    // Corner radii:
    //   top  → match bar strip bottom corners (flush join with the bar)
    //   bottom → panel rounding
    property real topLeftRadius:     8
    property real topRightRadius:    8
    property real bottomLeftRadius:  12
    property real bottomRightRadius: 12

    // Shadow — mirrors bar.stripShadow*
    property bool  shadowEnabled: false
    property real  shadowRadius:  12
    property color shadowColor:   Qt.rgba(0, 0, 0, 0.50)
    property real  shadowOffsetX: 0
    property real  shadowOffsetY: 4
}
