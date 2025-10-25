import QtQuick
import QtQuick.Controls 2.15

FocusScope {
    id: rootScope

    property var mo: appsModel
    property var modelExe: rootModel.modelForRow(0)
    property var searchModel: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null
    property bool listGeneralActive: listActive === "generalList"

    readonly property var modelActive: activeGroup ? folderAppModel : listGeneralActive ? mo : searchModel
    property var folderAppModel: null

    property bool visibleApps: true

    signal openGridApp(int ID)

    // Configuración de la cuadrícula
    readonly property int maxItemsPerRow: 5
    readonly property int maxItemsPerColumn: 3
    readonly property int cellWidth: 256
    readonly property int cellHeight: 256
    readonly property int iconSize: 96
    readonly property int marginPage: activeGroup ? 0 : (width - (cellWidth*maxItemsPerRow))/2
    readonly property int itemsPerPage: maxItemsPerRow * maxItemsPerColumn

    property int currentPage: 0
    property int totalPages

    function handleCreateGroup(index,item1,item2){
        var newGroupName = "folder apps" + (subModel.length + 1) // nombre genérico
        var newGroup = {
            displayGrupName: newGroupName,
            indexInModel: index,
            isGroup: true,
            elements: [
                { display: item1.display, decoration: item1.decoration, appIndex: item1.appIndex },
                { display: item2.display, decoration: item2.decoration, appIndex: item2.appIndex }
            ]
        }
        subModel.push(newGroup)

        function removeByAppIndex(appIndex) {
            for (var i = 0; i < appsModel.count; i++) {
                if (appsModel.get(i).appIndex === appIndex) {
                    appsModel.remove(i, 1)
                    break
                }
            }
        }

        removeByAppIndex(item1.appIndex)
        removeByAppIndex(item2.appIndex)

        appsModel.insert(index, {
            display: newGroupName,
            decoration: null,
            isGroup: true,
            modelGroup: [
                { display: item1.display, decoration: item1.decoration, appIndex: item1.appIndex },
                { display: item2.display, decoration: item2.decoration, appIndex: item2.appIndex }
            ]
        })
    }

    Item {
        id: gridRoot
        width: parent.width
        height:  parent.height
        //Visible: visibleApps

        property var folderAppModel: null

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onWheel: {
                iconsAnamitaionInitialLoad = true
                if (wheel.angleDelta.y > 0 && currentPage > 0) {
                    currentPage--
                } else if (wheel.angleDelta.y < 0 && currentPage < totalPages - 1) {
                    console.log("despues",currentPage)
                    currentPage++
                    console.log("despues",currentPage)
                }
                wheel.accepted = true
            }
            onClicked: {
                activeGroup = false
            }
        }


        Item {
            id: wrapper
            width: activeGroup ? (folderAppModel.count < maxItemsPerRow) ? folderAppModel.count*cellWidth : maxItemsPerRow*cellWidth : parent.width
            height: activeGroup ? ((Math.ceil(folderAppModel.count/maxItemsPerRow)) % maxItemsPerColumn)*cellHeight  : parent.height

            Behavior on anchors.leftMargin {
                enabled: iconsAnamitaionInitialLoad
                NumberAnimation {
                    id: marginAnimation
                    duration: 200
                    easing.type: Easing.InOutQuad

                    onRunningChanged: {
                        if (!running) {
                            iconsAnamitaionInitialLoad = false
                        }
                    }
                }
            }
            anchors.left: parent.left
            anchors.leftMargin: ((parent.width - width)/2) - currentPage * gridRoot.width
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: !activeGroup ? 0 : parent.width
                height: !activeGroup ? 0 :parent.height
                anchors.centerIn: parent
                visible: activeGroup
                color: Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.7)
                radius: 12
                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }
                Behavior on height {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }

            }



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
                        isGroup: model.isGroup
                        appIndex: model.appIndex
                        elementsVisible: visibleApps
                        dragActive: false
                        sizeIcon: iconSize
                        subModel: model.modelGroup

                        onDropOnItem: function(
                            draggedIndex,
                            draggedName,
                            draggedIcon,
                            draggedAppIndex,
                            targetIndex,
                            targetName,
                            targetIcon,
                            targetAppIndex
                        ) {
                            var draggedItem = { display: draggedName, decoration: draggedIcon, appIndex: draggedAppIndex }
                            var targetItem  = { display: targetName, decoration: targetIcon, appIndex: targetAppIndex }
                            console.log("Empalmado:", draggedName, "→", targetName)
                            handleCreateGroup(targetIndex,draggedItem,targetItem)
                        }

                        onOpenGroup: function (model){
                            folderAppModel = model
                            activeGroup = true
                        }


                    }

                    Component.onCompleted: {

                        totalPages = Math.ceil(index/(maxItemsPerRow*maxItemsPerColumn))
                    }
                }
            }
        }

        PageIndicator {
            id: pageIndicator
            count: totalPages
            currentIndex: currentPage
            visible: totalPages > 1
            anchors {
                bottom: parent.bottom
                topMargin: 10
                horizontalCenter: parent.horizontalCenter
            }

            // Navegación por clic en los puntos
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var clickedIndex = Math.floor(mouseX / (pageIndicator.width / pageIndicator.count))
                    if (clickedIndex >= 0 && clickedIndex < pageIndicator.count) {
                        currentPage = clickedIndex
                    }
                }
            }
        }

    }
}

