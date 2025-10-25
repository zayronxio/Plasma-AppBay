import QtQuick
import QtQuick.Controls 2.15
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

    signal openFolder
    signal closeFolder
    signal openGroup(var groupModel)

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
            duration: 180
            easing.type: Easing.OutQuad
        }
    }

    Component.onCompleted: {
        if (!searchActive) {
            appearAnim.start()
        }
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

            Flow {
                anchors.fill: parent

                Repeater {
                    anchors.fill: parent
                    model: subModel
                    delegate: Item {
                        width: bgGroup.active ? 256 : sizeIcon/2
                        height: bgGroup.active ? 256 : sizeIcon/2
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

        Kirigami.Icon {
            id: icon
            visible: !isGroup
            width: dragActive ? sizeIcon + 16 : sizeIcon
            height: width
            source: iconSource
            anchors.horizontalCenter: parent.horizontalCenter

            Behavior on width {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Text {
            anchors.top: icon.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            text: name
            width: parent.width - 10
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 12
            opacity: dragActive ? 0 : 1
            visible: opacity > 0 && !isGroup

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }
        }

        opacity: dragActive ? 0.9 : 1.0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }
    }

    // Área de drop para detectar cuando otro elemento se suelta aquí
    DropArea {
        anchors.fill: parent

        onEntered: function(drag) {
            console.log("DropArea entered")
            dropHighlight.opacity = 0.3
        }

        onExited: function(drag) {
            console.log("DropArea exited")
            dropHighlight.opacity = 0
        }

        onDropped: function(drop) {
            console.log("✓ DROPPED:", drop.source.name, "sobre", delegateRoot.name)
            dropHighlight.opacity = 0

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

        // NO usar drag.target - manejamos el arrastre manualmente

        onPressed: function(mouse) {
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
                    console.log("Drag started for:", delegateRoot.name)
                }
            }

            if (isDragging) {
                // Mover manualmente el dragContainer
                dragContainer.x = mouse.x - startPos.x
                dragContainer.y = mouse.y - startPos.y
            }
        }

        onReleased: function(mouse) {
            console.log("Mouse released, isDragging:", isDragging)

            if (isDragging) {
                // Finalizar el drag
                dragContainer.Drag.drop()

                if (!changeGroup) {
                    returnAnimation.start()
                }

                dragContainer.z = 0
                delegateRoot.dragActive = false
                isDragging = false
            } else {
                // Click simple - abrir el ítem
                iconsAnamitaionInitialLoad = false
                if (isGroup) {
                    openGroup(subModel)
                } else if (listGeneralActive) {
                    openGridApp(model.appIndex)
                } else {
                    rootModel.trigger(index, "", null)
                }
            }
        }

        onPressAndHold: function(mouse) {
            if (!isDragging) {
                isDragging = true
                delegateRoot.dragActive = true
                dragContainer.z = 9999
                console.log("Drag started (press and hold):", delegateRoot.name)
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
