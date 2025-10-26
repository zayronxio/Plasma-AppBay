import QtQuick
import "." as Module
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Item {
    property int entryHeight: 32
    property color entryColor: bgColor
    property color entryTextColor: Kirigami.Theme.textColor
    property double entryOpacity: 0.6
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

    Rectangle {
        id: background
        height: entryHeight
        width: 190
        anchors.horizontalCenter: parent.horizontalCenter
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

        Component.onCompleted: {
            searchText.forceActiveFocus()
            // Conectar la señal para recibir texto desde el PlasmoidItem
            Module.ToggleActive.newTextSearch.connect(function(str) {
                searchText.text += str
                searchText.forceActiveFocus()
            })

            // Conectar backspace
            Module.ToggleActive.backspace.connect(function() {
                if (searchText.text.length > 0) {
                    searchText.text = searchText.text.slice(0, -1)
                    searchText.forceActiveFocus()
                }
            })

            Module.ToggleActive.delateFullText.connect(function() {
                searchText.text = ""
            })

            // Conectar delete (suprimir)
            Module.ToggleActive.deleteKey.connect(function() {
                handleDeleteKey()
            })
        }
    }

    function clearText() {
        searchText.text = ""
        searchText.forceActiveFocus()
    }

    function setText(text) {
        searchText.text = text
        searchText.forceActiveFocus()
    }

    function handleDeleteKey() {
        if (searchText.text.length > 0) {
            // Si hay texto seleccionado, eliminar la selección
            if (searchText.selectedText.length > 0) {
                var start = searchText.selectionStart
                var end = searchText.selectionEnd
                searchText.text = searchText.text.substring(0, start) + searchText.text.substring(end)
                searchText.select(start, start) // Mover cursor al inicio de la selección
            } else {
                // Si no hay selección, eliminar el carácter en la posición del cursor
                var cursorPos = searchText.cursorPosition
                if (cursorPos < searchText.text.length) {
                    searchText.text = searchText.text.substring(0, cursorPos) + searchText.text.substring(cursorPos + 1)
                    searchText.cursorPosition = cursorPos
                }
            }
            searchText.forceActiveFocus()
        }
    }
}
