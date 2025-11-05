import QtQuick
import "Utils.js" as Utils
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.iconthemes as KIconThemes

FocusScope {
    id: rootScope

    property var mo: appsModel
    property var modelExe: rootModel.modelForRow(0)
    property var searchModel: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null
    property bool listGeneralActive: listActive === "generalList"

    readonly property var modelActive: activeGroup ? folderAppModel : listGeneralActive ? mo : searchModel

    property bool visibleApps: true

    signal openGridApp(int ID)


    // Configuración de la cuadrícula
    readonly property int maxItemsPerRow: Math.floor((width*.8)/cellWidth)
    readonly property int maxItemsPerColumn: Math.floor((height - cellHeight)/cellHeight)

    property real horizonBar: (Math.ceil(folderAppModel.count/maxItemsPerRow) < 3 ? Math.ceil(folderAppModel.count/maxItemsPerRow) :3)

    readonly property int cellWidth: Plasmoid.configuration.cellSize
    readonly property int cellHeight: Plasmoid.configuration.cellSize
    readonly property int iconSize: Plasmoid.configuration.iconSize
    readonly property int marginPage: /*/activeGroup ? 0 :/*/ (width - (cellWidth*maxItemsPerRow))/2
    readonly property int itemsPerPage: maxItemsPerRow * maxItemsPerColumn


    property int totalItems: 0
    readonly property int totalPages: Math.ceil(totalItems/(maxItemsPerRow*maxItemsPerColumn))

    property string nameActiveGroup
    property int activeIndex

    property int marginMinimalGroup: activeGroup ? folderAppModel.count < maxItemsPerRow ? ((maxItemsPerRow - folderAppModel.count)*cellWidth)/2 : 0 : 0

    onModelActiveChanged: {
        totalItems = 0
    }

    function handleCreateGroup(index, item1, item2) {
        var groupIndex = subModel ? subModel.length + 1 : 1
        var newGroupName = "Group " + groupIndex

        // Crear grupo para subModel
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
        saveSubModel()

        Utils.removeByAppIndex(item1.appIndex)
        Utils.removeByAppIndex(item2.appIndex)

        // Crear array JS puro para modelGroup
        var groupArray = [
            { display: item1.display, decoration: item1.decoration, appIndex: item1.appIndex },
            { display: item2.display, decoration: item2.decoration, appIndex: item2.appIndex }
        ]

        // Insertar grupo “vacío” primero
        appsModel.insert(index, {
            display: newGroupName,
            decoration: "",
            isGroup: true,
            modelGroup: [] // vacío temporal
        })

        // Actualizar inmediatamente con array JS puro para forzar render
        appsModel.set(index, {
            display: newGroupName,
            decoration: "",
            isGroup: true,
            modelGroup: groupArray
        })
        activeAnimations = false
        activeGroup = !activeGroup
        activeGroup = !activeGroup
        activeAnimations = true
    }







    function handleAddToGroup(targetIndex, draggedItem) {

        var target = appsModel.get(targetIndex)
        if (!target) {
            return
        }

        // Convertir a array real si es necesario
        var arrayModelGroup = Utils.toArray(target.modelGroup)

        arrayModelGroup.push({
            display: draggedItem.display,
            decoration: draggedItem.decoration,
            appIndex: draggedItem.appIndex
        })


        // ⚡ Actualizar subModel también
        for (var i = 0; i < subModel.length; i++) {
            if (subModel[i].displayGrupName === target.display) {
                subModel[i].elements = Utils.cloneToPureArray(arrayModelGroup)
                break
            }
        }

        // ⚡ Actualizar appsModel
        appsModel.set(targetIndex, {
            modelGroup: arrayModelGroup,
            display: target.display,
            isGroup: true
        })

        saveSubModel()

        Utils.removeByAppIndex(draggedItem.appIndex)
    }

    Kirigami.PromptDialog {
        id: rename
        title: "Rename Group"
        subtitle: "Enter a new name for this group"
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        preferredWidth: 320
        //preferredHeight: 188

        TextField {
            id: nameField
            width: parent.width
            height: 48
            horizontalAlignment: Text.AlignHCenter
            placeholderText: nameActiveGroup
            anchors.horizontalCenter: parent.horizontalCenter
            //leftPadding: 28 // Espacio fijo para el icono
            focus: true
            selectByMouse: true // Permitir selección de texto con mouse

            background: Rectangle {
                color: entryDialogColor
                radius: height/2
                opacity: 0.3
            }
        }
        onAccepted: {
            if (nameField.text.trim() !== "") {
                nameActiveGroup = nameField.text.trim()
                Utils.renameGroup(activeIndex, nameActiveGroup)
            }
        }
    }

    Item {
        id: gridRoot
        width: parent.width
        height:  parent.height
        //Visible: visibleApps

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onWheel: {
                iconsAnamitaionInitialLoad = true
                if (wheel.angleDelta.y > 0 && currentPage > 0) {
                    currentPage--
                } else if (wheel.angleDelta.y < 0 && currentPage < totalPages - 1) {
                    currentPage++
                }
                wheel.accepted = true
            }
            onClicked: {
                if (activeGroup) {
                    activeGroup = false
                    currentPage = oldPage
                } else {
                    // cuando se da click fuera del area de los iconos se cerrara el menu
                    dashboard.toggle()
                }

            }
        }


        Item {
            id: wrapper
            width: activeGroup ? (folderAppModel.count < maxItemsPerRow) ? folderAppModel.count*cellWidth : maxItemsPerRow*cellWidth : parent.width

            height: activeGroup ? horizonBar*cellHeight : parent.height

            property int marginFirstPageGroup: activeGroup ? (gridRoot.width-width)/2 : 0

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
            anchors.leftMargin: ((parent.width - width)/2) - currentPage * gridRoot.width - marginFirstPageGroup + marginMinimalGroup //activeGroup ? ((parent.width - width)/2) : ((parent.width - width)/2) - currentPage * gridRoot.width
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: bgGroup
                width: !activeGroup ? 0 : parent.width
                height: !activeGroup ? 0 :parent.height
                anchors.left: parent.left
                anchors.leftMargin: (gridRoot.width-width)/2 + (parent.width*currentPage) + (gridRoot.width-parent.width)*currentPage - marginMinimalGroup
                anchors.verticalCenter: parent.verticalCenter
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
                        isGroup: model.isGroup !== undefined ? model.isGroup : false
                        appIndex: model.appIndex !== undefined ? model.appIndex : -1
                        elementsVisible: visibleApps
                        dragActive: false
                        sizeIcon: iconSize
                        subModel: model.modelGroup
                        parentItem: bgGroup
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
                            handleCreateGroup(targetIndex,draggedItem,targetItem)
                        }
                        onDropOnItemGroup: function (
                            draggedIndex,
                            draggedName,
                            draggedIcon,
                            draggedAppIndex,
                            targetIndex
                        ) {
                            var draggedItem = {
                                display: draggedName,
                                decoration: draggedIcon,
                                appIndex: draggedAppIndex
                            }

                            handleAddToGroup(targetIndex, draggedItem)
                        }

                        onOpenGroup: function (model,indexGroup){

                            folderAppModel = model
                            parentGroupIndex = indexGroup
                            oldPage = currentPage
                            currentPage = 0
                            activeGroup = true

                        }
                        onRemoveAppInGroup: function (idx,nme) {
                            Utils.removeAppOfGroup(idx, nme)
                        }
                    }

                    Component.onCompleted: {
                        // ahora el conteo de los Items Activos es mas exacto
                        totalItems = listGeneralActive ? totalItems < model.index ? model.index : totalItems : model.index
                    }
                }
            }
        }

        PageIndicator {
            id: pageIndicator
            count: totalPages
            currentIndex: currentPage
            visible: totalPages > 1
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: wrapper.top
            anchors.topMargin: cellHeight*maxItemsPerColumn + 16


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

