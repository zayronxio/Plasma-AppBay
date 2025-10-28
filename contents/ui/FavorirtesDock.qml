import QtQuick
import org.kde.kirigami as Kirigami

Item {
    width: dock.width
    height: dock.height

    property var favModel: globalFavorites
    property int sizeIconDock
    property int spacingMargin
    property int maxIconsInDock
    Rectangle {
        id: dock
        width: favModel.count < maxIconsInDock ? (favModel + spacingMargin) * favModel.count : maxIconsInDock * (sizeIconDock + spacingMargin) + spacingMargin*4
        height: sizeIconDock + spacingMargin*2
        radius: height/2
        color:  Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.7)
    }
    Row {
        width: dock.width - spacingMargin*5
        height: sizeIconDock + spacingMargin*2
        anchors.horizontalCenter: dock.horizontalCenter
        spacing: spacingMargin
        Repeater {
            model: favModel

            delegate: Item {
                height: sizeIconDock + spacingMargin*2
                width: sizeIconDock
                Kirigami.Icon {
                    source: decoration
                    width: sizeIconDock
                    height: width
                    visible: index < maxIconsInDock
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            width: width + 16
                            globalFavorites.trigger(index, "", null)
                            dashboard.toggle()
                        }
                    }
                }
            }
        }
    }
}
