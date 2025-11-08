import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami

Item {
    property int entryHeight: 32
    property color entryColor: bgColor
    property color entryTextColor: Kirigami.Theme.textColor
    property double entryOpacity: 0.3
    property string placeholderText: "Search"
    property alias text: searchText.text

    property bool activeCursor: false

    function isColorLight(color) {
        let r = color.r * 255;
        let g = color.g * 255;
        let b = color.b * 255;
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b;
        return luminance > 127.5;
    }

    Keys.onPressed: (event) => {
        if (event.text !== "" && !event.ctrl && !event.alt && !event.meta) {
            event.accepted = true;
            searchActive = true
            searchText.text = event.text
            searchText.focus = true
        }
    }

    Rectangle {
        id: background
        height: entryHeight
        width: 190
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        radius: entryHeight/2
        color: Qt.rgba(entryColor.r,entryColor.g,entryColor.b,entryOpacity)
        border.width: 1
        border.color: isColorLight(entryColor) ? Qt.rgba(0, 0, 0, 0.3) : Qt.rgba(255, 255, 255, 0.2)

        TextField {
            id: searchText
            anchors.fill: parent
            color: entryTextColor
            horizontalAlignment: Text.AlignHCenter
            leftPadding: 28 // Espacio fijo para el icono
            focus: true
            selectByMouse: true // Permitir selección de texto con mouse

            background: Rectangle {
                color: "transparent"
            }

            onFocusChanged: {
                if (focus){
                    activeCursor = true
                } else {
                    activeCursor = false
                }
            }

            onTextChanged: {
                runnerModel.query = text;
                if (text == ""){
                    searchActive = false
                    listActive = "generalList"
                } else {
                    searchActive = true
                    listActive = "searchList"
                }
            }
        }


        // Placeholder personalizado cuando no hay texto
        Item {
            id: placeholder
            anchors.fill: parent
            visible: searchText.text === "" && !activeCursor
            enabled: false
            opacity: 0.7

            Kirigami.Icon {
                id: searchIcon
                source: "edit-find"
                width: 16
                height: 16
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: placeholderTextItem.left
                    rightMargin: 4
                }
                color: entryTextColor
            }

            Text {
                id: placeholderTextItem
                anchors.centerIn: parent
                text: placeholderText
                color: entryTextColor
                font: searchText.font
            }
        }

    }

    Item {
        id: mask
        width: background.width + 16
        height: background.height + 16
        anchors.centerIn: background
        visible:  false
        Rectangle {
            color: "black"
            width: background.width
            height: background.height
            anchors.centerIn: parent
            radius: background.radius
        }
    }

    MultiEffect {
        source: mask
        anchors.fill: mask
        //visible: false
        //shadowScale:  1.1
        shadowEnabled: true //Plasmoid.configuration.enabledShadow
        //blurMultiplier: 2
        blurMax: 22
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 2
        shadowOpacity: 0.2
        layer.enabled: true
        layer.effect: OpacityMask {
            invert: true
            maskSource: mask
        }
    }
}
