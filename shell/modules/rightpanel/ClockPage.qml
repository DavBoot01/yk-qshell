pragma ComponentBehavior: Bound

import QtQuick
import qs.themes
import qs.services

// ClockPage — the time, and a calendar to move through.
//
// The calendar has three views, zoomed out from one another by its title:
//
//   days     a month, Monday first, with ISO week numbers; six rows always,
//            the neighbouring months' days dimmed and taking you there
//   months   the year's twelve months
//   years    twelve years
//
// ‹ › and the wheel move by a month, a year or twelve years as the view
// spans; "Today" comes back. A day is selected with a click — the agenda will
// read `selected`. Keys, once the page has focus: ← → ↑ ↓ move the selected
// day, PgUp/PgDn a month (with Shift a year), Home today, Backspace zooms out,
// Enter zooms in.
//
// Every view takes the same height, so the panel does not resize as you move.
// Opening the page brings it back to today. A page of the right panel, which
// fits `preferredHeight`.
Item {
    id: root

    readonly property real preferredHeight: layout.implicitHeight + 16

    // ── Today ─────────────────────────────────────────────────────────────────
    property var _today: new Date()
    readonly property int _ty: _today.getFullYear()
    readonly property int _tm: _today.getMonth()
    readonly property int _td: _today.getDate()

    Timer {
        interval: 60000
        running:  true
        repeat:   true
        onTriggered: root._today = new Date()
    }

    readonly property var _loc: Qt.locale(Translation.effectiveCode)

    // ── What is shown ─────────────────────────────────────────────────────────
    property string view: "days"          // "days" | "months" | "years"
    property int    shownYear:  _ty
    property int    shownMonth: _tm       // 0-based
    property var    selected:   new Date(_ty, _tm, _td)

    readonly property int _blockStart: shownYear - ((shownYear % 12) + 12) % 12
    readonly property bool _atToday: view === "days" && shownYear === _ty && shownMonth === _tm
        && _same(selected, _ty, _tm, _td)

    function _same(date: var, y: int, m: int, d: int): bool {
        return date.getFullYear() === y && date.getMonth() === m && date.getDate() === d
    }

    function _cap(s: string): string {
        return s.length ? s.charAt(0).toLocaleUpperCase() + s.slice(1) : s
    }

    // ISO 8601 week of a date.
    function _week(y: int, m: int, d: int): int {
        const t = new Date(Date.UTC(y, m, d))
        t.setUTCDate(t.getUTCDate() + 3 - (t.getUTCDay() + 6) % 7)
        const jan4 = new Date(Date.UTC(t.getUTCFullYear(), 0, 4))
        return 1 + Math.round(((t - jan4) / 86400000 - 3 + (jan4.getUTCDay() + 6) % 7) / 7)
    }

    // ── Moving ────────────────────────────────────────────────────────────────
    // `dir` and `zoom` say how the next view comes in: from the side it moves
    // to, or grown or shrunk from the one it replaces.
    function _show(y: int, m: int, dir: int, zoom: int): void {
        const first = new Date(y, m, 1)
        root.shownYear  = first.getFullYear()
        root.shownMonth = first.getMonth()
        enter.dir  = dir
        enter.zoom = zoom
        enter.restart()
    }

    function step(n: int): void {
        if (root.view === "days")
            root._show(root.shownYear, root.shownMonth + n, n, 0)
        else
            root._show(root.shownYear + n * (root.view === "months" ? 1 : 12), root.shownMonth, n, 0)
    }

    function zoomOut(): void {
        if (root.view === "years")
            return
        root.view = root.view === "days" ? "months" : "years"
        root._show(root.shownYear, root.shownMonth, 0, -1)
    }

    function zoomIn(): void {
        if (root.view === "days")
            return
        root.view = root.view === "years" ? "months" : "days"
        root._show(root.shownYear, root.shownMonth, 0, 1)
    }

    function pickMonth(m: int): void {
        root.view = "days"
        root._show(root.shownYear, m, 0, 1)
    }

    function pickYear(y: int): void {
        root.view = "months"
        root._show(y, root.shownMonth, 0, 1)
    }

    function select(date: var): void {
        const dir = (date.getFullYear() - root.shownYear) * 12 + date.getMonth() - root.shownMonth
        const zoom = root.view !== "days" ? 1 : 0
        root.selected = date
        if (zoom || dir !== 0) {
            root.view = "days"
            root._show(date.getFullYear(), date.getMonth(), zoom ? 0 : Math.sign(dir), zoom)
        }
    }

    function moveSelected(days: int): void {
        const s = root.selected
        root.select(new Date(s.getFullYear(), s.getMonth(), s.getDate() + days))
    }

    function goToday(): void {
        root._today = new Date()
        const back = root.view !== "days"
        const dir = (root._ty - root.shownYear) * 12 + root._tm - root.shownMonth
        root.view = "days"
        root.selected = new Date(root._ty, root._tm, root._td)
        root._show(root._ty, root._tm, back ? 0 : Math.sign(dir), back ? 1 : 0)
    }

    // Opening the page starts from today.
    onVisibleChanged: {
        if (!visible)
            return
        root._today = new Date()
        root.view = "days"
        root.shownYear = root._ty
        root.shownMonth = root._tm
        root.selected = new Date(root._ty, root._tm, root._td)
        root.forceActiveFocus()
    }

    focus: true
    Keys.onPressed: event => {
        const shift = event.modifiers & Qt.ShiftModifier
        const days = root.view === "days"
        switch (event.key) {
        case Qt.Key_Left:      if (days) root.moveSelected(-1); else root.step(-1); break
        case Qt.Key_Right:     if (days) root.moveSelected(1);  else root.step(1);  break
        case Qt.Key_Up:        if (!days) return; root.moveSelected(-7); break
        case Qt.Key_Down:      if (!days) return; root.moveSelected(7);  break
        case Qt.Key_PageUp:    if (shift && days) root._show(root.shownYear - 1, root.shownMonth, -1, 0); else root.step(-1); break
        case Qt.Key_PageDown:  if (shift && days) root._show(root.shownYear + 1, root.shownMonth, 1, 0);  else root.step(1);  break
        case Qt.Key_Home:      root.goToday(); break
        case Qt.Key_Backspace: root.zoomOut(); break
        case Qt.Key_Return:
        case Qt.Key_Enter:     root.zoomIn(); break
        default: return
        }
        event.accepted = true
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    Column {
        id: layout
        anchors {
            top:     parent.top
            left:    parent.left
            right:   parent.right
            margins: 8
        }
        spacing: 10

        // ── Time ─────────────────────────────────────────────────────────────
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth:  _timeText.implicitWidth + _secsText.implicitWidth
            implicitHeight: _timeText.implicitHeight

            Text {
                id: _timeText
                anchors.left:           parent.left
                anchors.verticalCenter: parent.verticalCenter
                text:           Qt.formatTime(new Date(0, 0, 0, DateTime.hours, DateTime.minutes), "HH:mm")
                color:          Theme.widget.textColor
                font.family:    Theme.widget.fontFamily
                font.pixelSize: 30
                font.bold:      true
            }
            Text {
                id: _secsText
                anchors.left:   _timeText.right
                anchors.bottom: _timeText.bottom
                text:           ":" + String(DateTime.seconds).padStart(2, "0")
                color:          Theme.widget.textColorDim
                font.family:    Theme.widget.fontFamily
                font.pixelSize: 17
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           root._cap(root._today.toLocaleDateString(root._loc, "dddd d MMMM yyyy"))
            color:          Theme.widget.textColorDim
            font.family:    Theme.widget.fontFamily
            font.pixelSize: Theme.widget.fontSizeSmall
        }

        // ── Header: title (zooms out), Today, ‹ › ─────────────────────────────
        Item {
            width:  parent.width
            height: 28

            CalButton {
                anchors.left:           parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.view === "days"
                    ? root._cap(root._loc.standaloneMonthName(root.shownMonth)) + " " + root.shownYear
                    : root.view === "months" ? String(root.shownYear)
                    : root._blockStart + " – " + (root._blockStart + 11)
                bold:      true
                pixelSize: Theme.widget.fontSize
                enabled:   root.view !== "years"
                onClicked: root.zoomOut()
            }

            Row {
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                CalButton {
                    text:      Translation.tr("Today")
                    opacity:   root._atToday ? 0 : 1
                    enabled:   !root._atToday
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    onClicked: root.goToday()
                }
                CalButton { text: "󰅁"; square: true; onClicked: root.step(-1) }
                CalButton { text: "󰅂"; square: true; onClicked: root.step(1) }
            }
        }

        // ── The view ─────────────────────────────────────────────────────────
        Item {
            id: body
            width:  parent.width
            height: _cellH * 7 + 2 * 6
            clip:   true

            readonly property real _weekW: 22
            readonly property real _cellW: (width - _weekW) / 7
            readonly property real _cellH: 28

            // The wheel steps once per notch; a touchpad's small deltas add up.
            property real _wheel: 0
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    body._wheel += event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
                    while (Math.abs(body._wheel) >= 120) {
                        const n = body._wheel > 0 ? -1 : 1
                        body._wheel += n * 120
                        root.step(n)
                    }
                }
            }

            Item {
                id: content
                width:  parent.width
                height: parent.height
                transformOrigin: Item.Center

                ParallelAnimation {
                    id: enter
                    property int dir:  0
                    property int zoom: 0
                    NumberAnimation {
                        target: content; property: "x"
                        from: enter.dir * 36; to: 0
                        duration: 260; easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: content; property: "scale"
                        from: enter.zoom > 0 ? 0.86 : enter.zoom < 0 ? 1.14 : 1; to: 1
                        duration: 260; easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: content; property: "opacity"
                        from: 0; to: 1
                        duration: 200; easing.type: Easing.OutQuad
                    }
                }

                // ── Days ─────────────────────────────────────────────────────
                Column {
                    visible: root.view === "days"
                    width:   parent.width
                    spacing: 2

                    Row {
                        Text {
                            width:  body._weekW
                            height: body._cellH
                            text:   "#"
                            color:  Theme.widget.textColorDim
                            opacity: 0.6
                            font.family:    Theme.widget.fontFamily
                            font.pixelSize: Theme.widget.fontSizeSmall - 1
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment:   Text.AlignVCenter
                        }
                        Repeater {
                            model: 7
                            Text {
                                required property int index
                                width:  body._cellW
                                height: body._cellH
                                // Qt counts days from Sunday = 0; the week starts on Monday.
                                text:   root._cap(root._loc.dayName((index + 1) % 7, Locale.ShortFormat)).slice(0, 2)
                                color:  Theme.widget.textColorDim
                                font.family:    Theme.widget.fontFamily
                                font.pixelSize: Theme.widget.fontSizeSmall
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment:   Text.AlignVCenter
                            }
                        }
                    }

                    Repeater {
                        model: 6
                        Row {
                            id: week
                            required property int index
                            // The Monday this row starts on.
                            readonly property var monday: {
                                const first = new Date(root.shownYear, root.shownMonth, 1)
                                const offset = (first.getDay() + 6) % 7
                                return new Date(root.shownYear, root.shownMonth, 1 - offset + index * 7)
                            }

                            Text {
                                width:  body._weekW
                                height: body._cellH
                                text:   root._week(week.monday.getFullYear(), week.monday.getMonth(), week.monday.getDate())
                                color:  Theme.widget.textColorDim
                                opacity: 0.6
                                font.family:    Theme.widget.fontFamily
                                font.pixelSize: Theme.widget.fontSizeSmall - 1
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment:   Text.AlignVCenter
                            }

                            Repeater {
                                model: 7
                                CalCell {
                                    required property int index
                                    readonly property var date: new Date(week.monday.getFullYear(),
                                                                         week.monday.getMonth(),
                                                                         week.monday.getDate() + index)
                                    width:    body._cellW
                                    height:   body._cellH
                                    round:    true
                                    text:     String(date.getDate())
                                    outside:  date.getMonth() !== root.shownMonth
                                    current:  root._same(date, root._ty, root._tm, root._td)
                                    chosen:   root._same(root.selected, date.getFullYear(), date.getMonth(), date.getDate())
                                    onClicked: root.select(date)
                                }
                            }
                        }
                    }
                }

                // ── Months and years ─────────────────────────────────────────
                Grid {
                    id: wide
                    visible: root.view !== "days"
                    anchors.fill: parent
                    anchors.topMargin: 4
                    columns: 3
                    rowSpacing: 4
                    readonly property real _w: width / 3
                    readonly property real _h: (height - rowSpacing * 3) / 4

                    Repeater {
                        model: 12
                        CalCell {
                            id: cell
                            required property int index
                            readonly property bool months: root.view === "months"
                            readonly property int  year:   root._blockStart + index
                            width:   wide._w
                            height:  wide._h
                            text:    months ? root._cap(root._loc.standaloneMonthName(index, Locale.ShortFormat))
                                            : String(year)
                            current: months ? root.shownYear === root._ty && index === root._tm
                                            : year === root._ty
                            chosen:  months ? index === root.shownMonth : year === root.shownYear
                            onClicked: months ? root.pickMonth(cell.index) : root.pickYear(cell.year)
                        }
                    }
                }
            }
        }
    }
}
