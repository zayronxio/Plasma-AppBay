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
    readonly property int maxItemsPerRow: Math.floor((width*.8)/cellWidth)
    readonly property int maxItemsPerColumn: Math.floor((height - cellHeight)/cellHeight)
    readonly property int cellWidth: 256
    readonly property int cellHeight: 256
    readonly property int iconSize: 96
    readonly property int marginPage: activeGroup ? 0 : (width - (cellWidth*maxItemsPerRow))/2
    readonly property int itemsPerPage: maxItemsPerRow * maxItemsPerColumn

    property int currentPage: 0
    property int totalItems: 0
    readonly property int totalPages: Math.ceil(totalItems/(maxItemsPerRow*maxItemsPerColumn))

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

        removeByAppIndex(item1.appIndex)
        removeByAppIndex(item2.appIndex)

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



    function removeByAppIndex(appIndex) {
        for (var i = 0; i < appsModel.count; i++) {
            if (appsModel.get(i).appIndex === appIndex) {
                appsModel.remove(i, 1)
                break
            }
        }
    }

    function toArray(listModel) {
        var arr = []
        if (!listModel)
            return arr

            // Si es un QQmlListModel, recorre sus elementos
            if (listModel.count !== undefined) {
                for (var i = 0; i < listModel.count; i++) {
                    arr.push(listModel.get(i))
                }
            }
            // Si ya es array, simplemente devuélvelo
            else if (Array.isArray(listModel)) {
                arr = listModel
            }

            return arr
    }

    function cloneToPureArray(array) {
        var result = []
        for (var i = 0; i < array.length; i++) {
            var item = array[i]
            result.push({
                display: item.display,
                decoration: item.decoration,
                appIndex: item.appIndex
            })
        }
        return result
    }

    function handleAddToGroup(targetIndex, draggedItem) {
        console.log("🔹 handleAddToGroup llamado con targetIndex:", targetIndex)
        console.log("🔹 draggedItem:", JSON.stringify(draggedItem))

        var target = appsModel.get(targetIndex)
        if (!target) {
            console.log("⚠️ No se encontró el target en appsModel para targetIndex:", targetIndex)
            return
        }

        // Convertir a array real si es necesario
        var arrayModelGroup = toArray(target.modelGroup)

        console.log("📦 arrayModelGroup ANTES de push:", JSON.stringify(arrayModelGroup, null, 2))

        arrayModelGroup.push({
            display: draggedItem.display,
            decoration: draggedItem.decoration,
            appIndex: draggedItem.appIndex
        })

        console.log("✅ arrayModelGroup DESPUÉS de push:", JSON.stringify(arrayModelGroup, null, 2))

        // ⚡ Actualizar subModel también
        for (var i = 0; i < subModel.length; i++) {
            if (subModel[i].displayGrupName === target.display) {
                console.log("🔄 Actualizando subModel en índice", i, "para grupo", target.display,  JSON.stringify(arrayModelGroup) )
                subModel[i].elements = cloneToPureArray(arrayModelGroup)
                break
            }
        }

        // ⚡ Actualizar appsModel
        appsModel.set(targetIndex, {
            modelGroup: arrayModelGroup,
            display: target.display,
            isGroup: true
        })
        console.log("💾 appsModel actualizado en índice:", targetIndex)

        saveSubModel()
        console.log("💾 subModel guardado")

        removeByAppIndex(draggedItem.appIndex)
        console.log("🗑️ Eliminado elemento original con appIndex:", draggedItem.appIndex)

        console.log("✅ handleAddToGroup completado correctamente")
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
                    currentPage++
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
            anchors.leftMargin: activeGroup ? ((parent.width - width)/2) : ((parent.width - width)/2) - currentPage * gridRoot.width
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: bgGroup
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
                            console.log("Empalmado:", draggedName, "→", targetName)
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

                            console.log("Agregando", draggedName, "al grupo en índice", targetIndex)
                            handleAddToGroup(targetIndex, draggedItem)
                        }

                        onOpenGroup: function (model){
                            folderAppModel = model
                            activeGroup = true
                        }
                    }

                    Component.onCompleted: {
                        totalItems = index
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
            anchors.top: parent.top
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

