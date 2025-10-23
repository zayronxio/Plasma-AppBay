import QtQuick
import org.kde.kirigami as Kirigami

Item {
    anchors.fill: parent
    property var iconSource
    property var name
    property bool dragActive
    property int sizeIcon
    Kirigami.Icon {
        id: icon
        width: sizeIcon
        height: width
        source: iconSource
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Behavior on sizeIcon {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
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
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }
    }
}
