pragma ComponentBehavior: Bound

import QtQuick
import qs.themes
import qs.services

// CenterCarousel — horizontal pager for the CenterDropdown.
//
// Pages are declared once in `pages` ({ id, component }); add a page by adding
// an entry there — page map, count, dots and loaders all derive from it.
// The active page is driven by PanelManager.activeContentId.
//
// ── Navigation ────────────────────────────────────────────────────────────────
//   • Clicking a bar chip calls PanelManager.toggle/open → activeContentId changes
//     → carousel slides to the matching page.
//   • Dot indicators at the bottom call PanelManager.open with the target contentId.
//   • Horizontal drag snaps to the next/previous page when released past 25% threshold.
//     Rubber-band resistance is applied when dragging past the first/last page.
//
// ── Loading ───────────────────────────────────────────────────────────────────
//   Pages are lazy-loaded: a page is only instantiated when first needed.
//   Adjacent pages (±1) are pre-loaded as soon as a page becomes active,
//   so dragging to them always reveals a ready view.
//
// ── Animation ────────────────────────────────────────────────────────────────
//   The first open positions the carousel without animation (Qt.callLater trick).
//   Subsequent page changes animate via a NumberAnimation on pagesRow.x.
Item {
    id: root
    clip: true

    // ── Pages ─────────────────────────────────────────────────────────────────
    // `id` is the PanelManager contentId that selects the page.
    readonly property var pages: [
        { id: "system",  component: systemPage  },
        { id: "sensors", component: sensorsPage },
        { id: "network", component: networkPage }
    ]

    Component { id: systemPage;  SystemPage  {} }
    Component { id: sensorsPage; SensorsPage {} }
    Component { id: networkPage; NetworkPage {} }

    readonly property int _pageCount: root.pages.length

    // The centre tab shows the pages while the panel grows from it (Theme
    // centerDropdown.morph): the dots would say the same twice.
    readonly property bool _dots: !(Theme.bar.shape === "tabs" && Theme.centerDropdown.morph)

    function _indexOf(contentId: string): int {
        const i = root.pages.findIndex(p => p.id === contentId)
        return i >= 0 ? i : 0
    }

    readonly property int _targetPage: root._indexOf(PanelManager.activeContentId)

    // ── State ─────────────────────────────────────────────────────────────────
    // JS object: index → true when the page has been activated
    property var  _loadedPages: ({})
    property bool _initialized: false
    property real _dragStartX:  0

    // ── Snap animation ────────────────────────────────────────────────────────
    NumberAnimation {
        id: snapAnim
        target:      pagesRow
        property:    "x"
        duration:    Theme.animation.durationLong
        easing.type: Easing.OutExpo
    }

    // ── Page container ────────────────────────────────────────────────────────
    // pagesRow is wider than the visible area; only one page is visible at a time
    // because root has clip:true. pagesRow.x is managed by snapToPage().
    Item {
        id: pagesRow
        anchors.top:    parent.top
        anchors.bottom: root._dots ? dotRow.top : parent.bottom
        anchors.bottomMargin: root._dots ? 4 : 0
        width:  root.width * root._pageCount
        // x: managed imperatively by snapToPage() and DragHandler

        Repeater {
            model: root.pages

            delegate: Loader {
                id: pageLoader
                required property int index
                required property var modelData

                active:          !!root._loadedPages[pageLoader.index]
                x:               root.width * pageLoader.index
                width:           root.width
                height:          pagesRow.height
                sourceComponent: pageLoader.modelData.component
            }
        }
    }

    // ── Dot indicators ────────────────────────────────────────────────────────
    Row {
        id: dotRow
        visible: root._dots
        anchors.bottom:           parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin:     8
        spacing: 8

        Repeater {
            model: root._pageCount
            delegate: Rectangle {
                required property int index

                readonly property bool _active: index === root._targetPage

                width:   8
                height:  8
                radius:  4
                color:   _active ? Theme.colors.primary : Theme.colors.outline
                opacity: _active ? 1.0 : 0.5

                Behavior on color   { ColorAnimation  { duration: Theme.animation.duration } }
                Behavior on opacity { NumberAnimation  { duration: Theme.animation.duration } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    // Expand the hit area slightly for easier clicking
                    anchors.margins: -4
                    onClicked: PanelManager.open(
                        "center-dropdown",
                        root.pages[index].id,
                        PanelManager.activeContent,
                        PanelManager.activeScreen
                    )
                }
            }
        }
    }

    // ── Drag handler ──────────────────────────────────────────────────────────
    DragHandler {
        id: dragHandler
        target:        null       // manual control of pagesRow.x
        xAxis.enabled: true
        yAxis.enabled: false

        onActiveChanged: {
            if (active) {
                snapAnim.stop()
                root._dragStartX = pagesRow.x
                // Pre-load adjacent pages so they're ready when the drag reaches them
                root._preloadAdjacent(root._targetPage)
            } else {
                // Drag ended — decide whether to snap to a new page
                var offset    = pagesRow.x - root._dragStartX
                var threshold = root.width * 0.25
                var cur       = root._targetPage
                var next      = cur

                if (offset < -threshold)
                    next = Math.min(root._pageCount - 1, cur + 1)
                else if (offset > threshold)
                    next = Math.max(0, cur - 1)

                if (next !== cur) {
                    // Navigate to the new page; Connections will trigger the snap
                    PanelManager.open(
                        "center-dropdown",
                        root.pages[next].id,
                        PanelManager.activeContent,
                        PanelManager.activeScreen
                    )
                } else {
                    // Snap back to current page
                    root.snapToPage(cur, true)
                }
            }
        }

        onTranslationChanged: {
            if (!active) return
            var newX = root._dragStartX + translation.x
            var minX = -(root._pageCount - 1) * root.width
            var maxX = 0
            // Rubber-band: dampen movement past first/last page
            if (newX < minX)      newX = minX + (newX - minX) * 0.3
            else if (newX > maxX) newX = newX * 0.3
            pagesRow.x = newX
        }
    }

    // ── React to page changes from PanelManager ───────────────────────────────
    Connections {
        target: PanelManager
        function onActiveContentIdChanged() {
            if (PanelManager.activePanelId !== "center-dropdown") return
            var idx = root._indexOf(PanelManager.activeContentId)
            root._preloadAdjacent(idx)
            root.snapToPage(idx, root._initialized)
        }
    }

    // Keep the strip aligned when the panel is resized (e.g. other screen).
    onWidthChanged: if (root._initialized) root.snapToPage(root._targetPage, false)

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    Component.onCompleted: {
        var idx = root._indexOf(PanelManager.activeContentId)
        root._preloadAdjacent(idx)
        root.snapToPage(idx, false)         // immediate — no animation on first open
        Qt.callLater(function() { root._initialized = true })
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    // Snap pagesRow.x to the position of page `idx`.
    // animate=true plays the OutExpo transition; false sets x instantly.
    function snapToPage(idx, animate) {
        snapAnim.stop()
        var targetX = -(idx * root.width)
        if (animate) {
            snapAnim.to = targetX
            snapAnim.start()
        } else {
            pagesRow.x = targetX
        }
    }

    // Mark page `idx` and its neighbours as loaded.
    // Reassigns _loadedPages to trigger Loader.active bindings.
    function _preloadAdjacent(idx) {
        var updated = Object.assign({}, root._loadedPages)
        if (idx > 0)                    updated[idx - 1] = true
        updated[idx]                                     = true
        if (idx < root._pageCount - 1) updated[idx + 1] = true
        root._loadedPages = updated
    }
}
