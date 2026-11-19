pragma ComponentBehavior: Bound

import QtQuick

import qs.themes
import qs.services

// PageTabs — a panel's pages, shown in the bar tab that grows the panel while
// it is open (TabDrawer): the active page with its icon and label, the others
// by their icon. A click turns the page; the active one closes the panel.
//
// The item spans the tab's body and clips to it, so each tab rises in from the
// body's bottom edge — the panel's side: the page the panel opened on first,
// the others outwards from it.
//
//   PageTabs { drawer: centerDrawer; pages: [{ id, icon, label }, …] }
Item {
    id: root

    required property TabDrawer drawer
    required property var pages
    property real rise: 12

    clip:    true
    visible: root.drawer.t > root.drawer.style.headerStage[0] && root.pages.length > 0

    Row {
        anchors.verticalCenter: parent.verticalCenter
        x:       Math.round((parent.width - width) / 2)
        spacing: 4
        enabled: root.drawer.open

        Repeater {
            model: root.pages
            delegate: Rectangle {
                id: pageTab
                required property var modelData
                required property int index

                readonly property bool _active: PanelManager.activeContentId === modelData.id
                    || (!root.drawer.open && root.drawer.lastPage === modelData.id)

                // 0 for the page the panel opened on, then by distance.
                readonly property int _rank: {
                    const a = root.pages.findIndex(p => p.id === root.drawer.lastPage)
                    return a < 0 ? pageTab.index : Math.abs(pageTab.index - a)
                }
                readonly property real _shown: root.drawer.page(pageTab._rank)

                opacity:   pageTab._shown
                transform: Translate { y: (1 - pageTab._shown) * root.rise }

                height: Theme.sizes.barHeight - Theme.bar.pill.verticalMargin * 2
                width:  tabRow.implicitWidth + 20
                radius: height / 2
                color:  pageTab._active ? Theme.widget.activeBackground
                      : tabMouse.containsMouse ? Theme.widget.hoverBackground : "transparent"

                Behavior on width { NumberAnimation { duration: Theme.animation.duration; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation  { duration: Theme.animation.duration } }

                Row {
                    id: tabRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:           pageTab.modelData.icon
                        color:          pageTab._active ? Theme.colors.primary : Theme.widget.textColorDim
                        font.family:    Theme.widget.fontFamily
                        font.pixelSize: Theme.widget.fontSize
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible:        pageTab._active
                        text:           Translation.tr(pageTab.modelData.label)
                        color:          Theme.widget.textColor
                        font.family:    Theme.widget.fontFamily
                        font.pixelSize: Theme.widget.fontSize
                        font.bold:      true
                    }
                }

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: PanelManager.toggle(root.drawer.panelId, pageTab.modelData.id,
                                                   PanelManager.activeContent, root.drawer.screen)
                }
            }
        }
    }
}
