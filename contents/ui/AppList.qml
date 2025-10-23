import QtQuick
import QtQuick.Controls 2.15

FocusScope {
    id: rootScope

    property var mo: appsModel
    property var modelExe: rootModel.modelForRow(0)
    property var searchModel: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null
    property bool listGeneralActive: listActive === "generalList"

    readonly property var modelActive: listGeneralActive ? mo : searchModel

    signal openGridApp(int ID)

    // Configuración de la cuadrícula
    readonly property int maxItemsPerRow: 5
    readonly property int maxItemsPerColumn: 3
    readonly property int cellWidth: 256
    readonly property int cellHeight: 256
    readonly property int iconSize: 96
    readonly property int marginPage: (width - (cellWidth*maxItemsPerRow))/2
    readonly property int itemsPerPage: maxItemsPerRow * maxItemsPerColumn

    property int currentPage: 0
    property int totalPages

    Item {
        id: gridRoot
        width: parent.width
        height:  parent.height

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onWheel: {
                if (wheel.angleDelta.y > 0 && currentPage > 0) {
                    currentPage--
                } else if (wheel.angleDelta.y < 0 && currentPage < totalPages - 1) {
                    currentPage++
                }
                wheel.accepted = true
            }
        }


        Item {
            id: wrapper
            width: parent.width
            height:  parent.height
            Behavior on x {
                NumberAnimation { duration: 350; easing.type: Easing.InOutQuad }
            }
            x: -currentPage * gridRoot.width

            Repeater {
                model: modelActive

                delegate: Item {
                    width: cellWidth
                    height: cellHeight

                    property int page: Math.floor(index / itemsPerPage)
                    property int localIndex: index % itemsPerPage
                    property int row: localIndex % maxItemsPerRow
                    property int column: Math.floor(localIndex / maxItemsPerRow)
                    property int extraPadding: page > 0 ? marginPage + (marginPage*page) : marginPage

                    x: (row * cellWidth) + (page * (maxItemsPerRow * cellWidth + marginPage)) + extraPadding
                    y: column * cellHeight

                    ListDelegate {
                        anchors.fill: parent
                        iconSource: model.icon || model.decoration
                        name: model.name || model.display
                        dragActive: false
                        sizeIcon: iconSize
                    }

                    Component.onCompleted: {
                        totalPages = Math.ceil(index/(maxItemsPerRow*maxItemsPerColumn))
                    }
                }
            }
        }

    }
}

