import QtQuick
import QtQuick.Controls 2.15
import org.kde.kirigami as Kirigami

Item {
    id: delegateRoot
    anchors.fill: parent
    property var iconSource
    property var name
    property bool dragActive: false
    property int sizeIcon
    property int itemIndex: index
    property var itemModel: model
    property bool elementsVisible: true
    property bool isGroup
    property var subModel

    // Señal para notificar cuando se suelta sobre otro elemento
    signal dropOnItem(int draggedIndex, var draggedModel, int targetIndex, var targetModel)
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
        /*/ efecto rebote desabilitado
        PropertyAnimation {
            target: delegateRoot
            property: "appearScale"
            from: 1.1
            to: 1.0
            duration: 200
            easing.type: Easing.InOutQuad
        }/*/
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
        id: dropArea
        anchors.fill: parent

        onEntered: {
            // Visual feedback cuando un elemento entra en esta área
            dropHighlight.opacity = 0.3
        }

        onExited: {
            dropHighlight.opacity = 0
        }

        onDropped: function(drop) {
            dropHighlight.opacity = 0
            // Emitir señal con los índices de ambos elementos
            if (drop.source && drop.source.itemIndex !== itemIndex) {
                delegateRoot.dropOnItem(
                    drop.source.itemIndex,
                    drop.source.itemModel,
                    itemIndex,
                    itemModel
                )
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
        anchors.fill: parent
        property bool changeGroup: false

        // Para que Drag.source funcione
        drag.target: dragContainer

        QtObject {
            id: origin
            property int x
            property int y
        }

        // Click sostenido para activar arrastre
        onPressAndHold: {
            if (pressed) {
                dragContainer.Drag.active = true
                dragContainer.Drag.source = delegateRoot
                dragContainer.z = 9999
                delegateRoot.dragActive = true
            }
        }

        // Guardar posición original al presionar
        onPressed: {
            origin.x = dragContainer.x
            origin.y = dragContainer.y
        }

        // Restaurar al soltar
        onReleased: {
            dragContainer.Drag.active = false

            if (!changeGroup) {
                returnAnimation.start()
            }

            dragContainer.z = 0
            delegateRoot.dragActive = false
        }

        // Click simple para abrir
        onClicked: {
            iconsAnamitaionInitialLoad = false
            if (isGroup) {
                openGroup(subModel)
                //openFolder()
            } else if (listGeneralActive) {
                openGridApp(model.appIndex)
            } else {
                rootModel.trigger(index, "", null)
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
