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

    // Morph (bar shape "tabs"): the centre tab grows the panel out of itself,
    // as a drawer — the tab widens along the bar while its chips give way to
    // the panel's page tabs, then the panel drops at its own width, then its
    // content fades in; closing runs it backwards.
    property bool morph:          true
    property int  openDuration:   520
    property int  closeDuration:  360
    // The panel's width: a share of the screen's, within these bounds.
    property real widthFraction:  0.40
    property real minWidth:       560
    property real maxWidth:       900
    // Room the widened tab leaves to the side tabs.
    property real tabGap:         24
    // Each stage's [start, end], as shares of the time.
    property var  chipsStage:     [0.00, 0.15]
    property var  widenStage:     [0.00, 0.38]
    property var  headerStage:    [0.18, 0.42]
    property var  dropStage:      [0.28, 0.88]
    property var  contentStage:   [0.60, 1.00]
    // How far the content rises as it fades in.
    property real contentRise:    10

    // Shadow — mirrors bar.stripShadow*
    property bool  shadowEnabled: false
    property real  shadowRadius:  12
    property color shadowColor:   Qt.rgba(0, 0, 0, 0.50)
    property real  shadowOffsetX: 0
    property real  shadowOffsetY: 4
}
