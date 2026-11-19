pragma ComponentBehavior: Bound

import QtQuick

import qs.services

// TabDrawer — the state of a panel a bar tab grows out of itself, as a drawer.
//
// It draws nothing: BarContainer reads its stages to shape the tab (BarTab's
// drop), to swap the pill's chips for the page tabs (PageTabs), and to place
// the panel's content.
//
// One progress `t`, linear in time, runs 0 → 1 on opening and back on closing;
// a reversal mid-way takes the share of the time that is left. Each stage is
// `t` eased over a [start, end] share of the time the `style` gives:
//
//   chips    the pill's chips rise out of the tab and fade
//   widen    the tab widens along the bar
//   drop     the panel drops from the tab
//   content  the panel's content fades in
//   page(r)  the page tab of rank r rises in (`headerStage`, `tabStagger` later per rank)
//
// `style` is a theme group carrying openDuration and closeDuration, and the
// stages it uses: chipsStage, widenStage, headerStage with tabStagger,
// dropStage, contentStage; any other range is read with `stage()`.
Item {
    id: d

    required property string panelId
    required property var    screen
    required property var    style
    property bool enabled: true

    readonly property bool open: d.enabled
        && PanelManager.activePanelId === d.panelId
        && (PanelManager.activeScreen ?? d.screen) === d.screen
    // Anything of it shows: opening, open or closing.
    readonly property bool shown: d.t > 0

    property real t: 0

    function ease(x: real): real {
        const c = Math.max(0, Math.min(1, x))
        return 1 - Math.pow(1 - c, 4)
    }
    // A stage the style does not give stays at 0.
    function stage(range: var): real {
        if (!range)
            return 0
        return d.ease((d.t - range[0]) / Math.max(0.001, range[1] - range[0]))
    }
    function page(rank: int): real {
        const s = d.style.tabStagger * rank
        return d.stage([d.style.headerStage[0] + s, d.style.headerStage[1] + s])
    }

    readonly property real chips:   d.stage(d.style.chipsStage)
    readonly property real widen:   d.stage(d.style.widenStage)
    readonly property real drop:    d.stage(d.style.dropStage)
    readonly property real content: d.stage(d.style.contentStage)

    // The content stays while the panel closes, even when another panel has
    // already taken the manager; so does the page it showed last.
    property Component panelContent: null
    property string lastPage: ""

    Binding {
        target:      d
        property:    "panelContent"
        value:       PanelManager.activeContent
        when:        d.open
        restoreMode: Binding.RestoreNone
    }

    Connections {
        target: PanelManager
        function onActiveContentIdChanged(): void {
            if (d.open)
                d.lastPage = PanelManager.activeContentId
        }
    }

    onOpenChanged: {
        if (d.open) {
            d.lastPage = PanelManager.activeContentId
            closing.stop()
            opening.duration = d.style.openDuration * (1 - d.t)
            opening.restart()
        } else if (d.t > 0) {
            opening.stop()
            closing.duration = d.style.closeDuration * d.t
            closing.restart()
        }
    }

    NumberAnimation {
        id: opening
        target: d; property: "t"; to: 1
    }
    NumberAnimation {
        id: closing
        target: d; property: "t"; to: 0
        onFinished: d.panelContent = null
    }
}
