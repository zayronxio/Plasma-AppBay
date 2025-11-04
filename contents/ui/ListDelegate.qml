import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Effects
import org.kde.plasma.plasmoid
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami

Item {
    id: delegateRoot
    anchors.fill: parent
    property var iconSource
    property var name
    property int appIndex
    property bool dragActive: false
    property int sizeIcon
    property int itemIndex: index
    property var itemModel: model
    property bool elementsVisible: true
    property bool isGroup
    property var subModel

    property var parentItem

    property bool full: false

    // Señal para notificar cuando se suelta sobre otro elemento
    signal dropOnItem(
        int draggedIndex,
        string draggedName,
        string draggedIcon,
        int draggedAppIndex,
        int targetIndex,
        string targetName,
        string targetIcon,
        int targetAppIndex
    )

    signal dropOnItemGroup(
        int draggedIndex,
        string draggedName,
        string draggedIcon,
        int draggedAppIndex,
        int targetIndex
    )

    signal openFolder
    signal closeFolder
    signal openGroup(var groupModel, int indexGroup)

    signal removeAppInGroup(int index, string value)

    // Efecto de aparición
    property real appearScale: 1.0


    transform: Scale {
        id: scaleEffect
        origin.x: delegateRoot.width / 2
        origin.y: delegateRoot.height / 2
        xScale: appearScale
        yScale: appearScale
    }



    SequentialAnimation {
        id: appearAnim
        PropertyAnimation {
            target: delegateRoot
            property: "appearScale"
            from: 0.0
            to: 1.0
            duration: activeAnimations ? 150 : 0
            easing.type: Easing.OutQuad
        }
    }

    Component.onCompleted: {
        if (!searchActive) {
            appearAnim.start()
        }
    }

    ContextMenu {
        id: contextMenu
        indexInAppsModel: model.index
        currentName: model.display
        isGruop: model.isGroup
    }


    Item {
        id: dragContainer
        width: parent.width
        height: parent.height
        x: 0
        y: 0

        // Configuración del sistema Drag - CLAVE: NO usar drag.target en MouseArea
        Drag.active: mouseArea.pressed && mouseArea.isDragging
        Drag.source: delegateRoot
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        Rectangle {
            id: bgGroup
            visible: isGroup
            radius: 8
            width: sizeIcon
            height: sizeIcon
            color: Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.7)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            Flow {
                anchors.fill: parent

                Repeater {
                    anchors.fill: parent
                    model: subModel
                    delegate: Item {
                        width: bgGroup.active ? 256 : sizeIcon/2
                        height: bgGroup.active ? 256 : sizeIcon/2
                        visible: index < 4
                        Kirigami.Icon {
                            id: iconGroup
                            width: bgGroup.active ? sizeIcon : parent.width/2
                            height: width
                            source: model.decoration
                            anchors.centerIn: parent
                        }
                    }
                }
            }
        }


        Item {
            id: itemEffect
            anchors.fill: parent

            Kirigami.Icon {
                id: icon
                visible: !isGroup
                width: dragActive ? sizeIcon + 16 : sizeIcon
                height: width
                source: iconSource
                opacity: full ? 0 : 1
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                Behavior on width {
                    NumberAnimation {
                        //enabled: activeAnimations
                        duration: activeAnimations ? 200 : 0
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Kirigami.Heading {
                id: nameDisplay
                anchors.top: icon.bottom
                anchors.topMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                text: name
                width: parent.width - 10
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                level: 5
                opacity: dragActive ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }


        MultiEffect {
            source: itemEffect
            anchors.fill: itemEffect
            //visible: false
            //shadowScale:  1.1
            shadowEnabled: Plasmoid.configuration.enabledShadow
            blurMultiplier: 2
            blurMax: 18
            shadowOpacity: 0.2
        }
    }

    // Área de drop para detectar cuando otro elemento se suelta aquí
    DropArea {
        anchors.fill: parent

        onEntered: function(drag) {
            dropHighlight.opacity = 0.3
        }

        onExited: function(drag) {
            dropHighlight.opacity = 0
        }

        onDropped: function(drop, drag) {
            dropHighlight.opacity = 0

            if (!activeGroup) {
                if (!drop.source.isGroup) {
                    if (isGroup) {
                        delegateRoot.dropOnItemGroup(
                            drop.itemIndex,
                            drop.source.name,
                            drop.source.iconSource,
                            drop.source.appIndex,
                            delegateRoot.itemIndex
                        )
                    } else {
                        delegateRoot.dropOnItem(
                            drop.itemIndex,
                            drop.source.name,
                            drop.source.iconSource,
                            drop.source.appIndex,
                            delegateRoot.itemIndex,
                            delegateRoot.name,
                            delegateRoot.iconSource,
                            delegateRoot.appIndex
                        )
                    }
                }
            } else {
                console.log("🟢 Elemento soltado dentro del grupo activo")
            }
        }
    }

    // Highlight visual para indicar zona de drop
    Rectangle {
        id: dropHighlight
        anchors.fill: parent
        color: Kirigami.Theme.highlightColor
        radius: 8
        opacity: 0
        z: -1

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.InOutQuad
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent

        property bool changeGroup: false
        property bool isDragging: false
        property point startPos
        property int dragThreshold: 10

        acceptedButtons: Qt.LeftButton | Qt.RightButton

        // NO usar drag.target - manejamos el arrastre manualmente

        onPressed: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                contextMenu.open(mouse.x,mouse.y,model.appIndex)
                //contextMenu.x = mouse.x
                //contextMenu.y = mouse.y
                mouse.accepted = true
                return
            }
            startPos = Qt.point(mouse.x, mouse.y)
            isDragging = false
        }

        onPositionChanged: function(mouse) {
            if (pressed && !isDragging) {
                var dx = mouse.x - startPos.x
                var dy = mouse.y - startPos.y
                var distance = Math.sqrt(dx * dx + dy * dy)

                if (distance > dragThreshold) {
                    isDragging = true
                    delegateRoot.dragActive = true
                    dragContainer.z = 9999
                }
            }

            if (isDragging) {
                // Mover manualmente el dragContainer
                dragContainer.x = mouse.x - startPos.x
                dragContainer.y = mouse.y - startPos.y
            }
        }

        onReleased: function(mouse) {
            if (isDragging) {

                if (activeGroup) {
                    // logica para determinar donde se solto el icono
                    var globalParentPos = parentItem.mapToGlobal(mouse.x, mouse.y)

                    var realx = globalParentPos.x + parent.width*(model.index%maxItemsPerRow-1)

                    var realY = mouse.y + dragContainer.height*((Math.floor(model.index/maxItemsPerRow)%maxItemsPerColumn))

                    if ((realx > parentItem.width || realY > parentItem.height ) || (realx < 0 || realY < 0)) {

                        removeAppInGroup(parentGroupIndex,model.display) // envia señal para procesar la eliminacion de los datos
                    }
                }


                dragContainer.Drag.drop()

                if (!changeGroup) {
                    returnAnimation.start()
                }

                dragContainer.z = 0
                delegateRoot.dragActive = false
                isDragging = false

            } else {
                if (mouse.button === Qt.LeftButton) {
                    iconsAnamitaionInitialLoad = false
                    if (isGroup) {
                        openGroup(subModel,model.index)
                    } else if (listGeneralActive) {
                        openGridApp(model.appIndex)
                    } else {
                        rootModel.trigger(index, "", null)
                    }
                }
            }
        }


        onPressAndHold: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                if (!isDragging) {
                    isDragging = true
                    delegateRoot.dragActive = true
                    dragContainer.z = 9999
                }
            }
        }
    }

    // Animación para regresar a la posición original
    ParallelAnimation {
        id: returnAnimation
        NumberAnimation {
            target: dragContainer
            property: "x"
            to: 0
            duration: 300
            easing.type: Easing.OutBack
        }
        NumberAnimation {
            target: dragContainer
            property: "y"
            to: 0
            duration: 300
            easing.type: Easing.OutBack
        }
    }
}
