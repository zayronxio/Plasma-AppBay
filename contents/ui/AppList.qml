import QtQuick
import QtQuick.Controls 2.15
import org.kde.kirigami as Kirigami

FocusScope {
    id: rootScope

    property var mo: appsModel
    property var modelExe: rootModel.modelForRow(0)
    property int itemsPerPage: 18
    property int currentPage: 0

    property bool isDragging: true

    readonly property int totalPages: Math.ceil(mo.count / itemsPerPage)

    signal openGridApp(int ID)
    Column {
        anchors.fill: parent
        spacing: 10

        // PageIndicator interactivo
        PageIndicator {
            id: pageIndicator
            count: totalPages
            currentIndex: currentPage
            visible: totalPages > 1
            anchors.top: swipeView.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var itemWidth = parent.width / parent.count
                    var clickedIndex = Math.floor(mouseX / itemWidth)
                    if (clickedIndex >= 0 && clickedIndex < parent.count) {
                        currentPage = clickedIndex
                        rootScope.forceActiveFocus()
                    }
                }
            }
        }

        SwipeView {
            id: swipeView
            width: parent.width
            height: parent.height - (pageIndicator.visible ? pageIndicator.height + 10 : 0)
            currentIndex: currentPage
            interactive: isDragging

            // NO debe tener foco ni manejar teclas
            focus: false
            Keys.enabled: false

            Repeater {
                model: totalPages

                Item {
                    focus: false

                    GridView {
                        id: grid
                        width: parent.width * .7
                        height: parent.height
                        cellWidth: width / 6
                        cellHeight: cellWidth
                        anchors.centerIn: parent

                        // GridView tampoco debe tener foco ni ser interactivo con teclado
                        focus: false
                        interactive: false

                        model: {
                            var startIndex = index * itemsPerPage
                            var endIndex = Math.min(startIndex + itemsPerPage, mo.count)
                            var pageModel = []
                            for (var i = startIndex; i < endIndex; i++) {
                                pageModel.push(mo.get(i))
                            }
                            return pageModel
                        }

                        delegate: Item {
                            width: grid.cellWidth
                            height: width

                            opacity: 1.0

                            property int sizeIcon: 96
                            property int sizeIconDefalt: 96
                            property bool drogActive: false

                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                            Kirigami.Icon {
                                id: icon
                                width: sizeIcon
                                height: width
                                source: modelData.icon
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Behavior on sizeIcon {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.InOutQuad
                                }
                            }

                            Text {
                                anchors.top: icon.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.name
                                width: parent.width - 10
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: 12
                                opacity: drogActive ? 0 : 1
                                visible: opacity > 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }


                            MouseArea {
                                anchors.fill: parent
                                //drag.target: parent

                                property bool changeGrup: false

                                QtObject {
                                    id: origin
                                    property int x
                                    property int y
                                }
                                onPressAndHold: {
                                    if(pressed) {
                                        drag.target = parent
                                        parent.z = 9999
                                        parent.opacity = 0.9
                                        parent.sizeIcon = sizeIcon + 16
                                        parent.drogActive = true
                                        isDragging = false
                                    }
                                }
                                onPressed: {
                                    origin.x = parent.x
                                    origin.y = parent.y
                                }
                                onReleased: {
                                    if(!changeGrup) {
                                        parent.x = origin.x
                                        parent.y = origin.y
                                    }
                                    isDragging = true
                                    drag.target = null
                                    parent.opacity = 1.9
                                    parent.sizeIcon = sizeIcon - 16
                                    parent.drogActive = false
                                }
                                onClicked: {
                                    openGridApp(modelData.appIndex)
                                }
                            }
                        }

                    }
                }
            }
        }
    }

    onCurrentPageChanged: {
        if (swipeView.currentIndex !== currentPage) {
            swipeView.currentIndex = currentPage
        }
    }

    Component.onCompleted: {
        swipeView.currentIndexChanged.connect(function() {
            if (currentPage !== swipeView.currentIndex) {
                currentPage = swipeView.currentIndex
            }
        })
    }
}
