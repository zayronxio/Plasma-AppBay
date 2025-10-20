import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.kicker 0.1 as Kicker
import "." as Module

Item {
    id: root


    property QtObject dashWindow: null
    /*/
    readonly property Component dashWindowComponent: kicker.isDash ? Qt.createComponent(Qt.resolvedUrl("./Deshboard.qml"), root) : null
    readonly property Kicker.DashboardWindow dashWindow: dashWindowComponent && dashWindowComponent.status === Component.Ready
    ? dashWindowComponent.createObject(root, { visualParent: root }) : null/*/
    signal visibleToggle

    function handleToggle() {
        dashWindow.visible = false
    }

    Kirigami.Icon {
        width: 22
        height: 22
        source: "configure"
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if(dashWindow !== null){
                    root.dashWindow.visible = !dashWindow.visible
                }

            }
        }
    }

    Component.onCompleted: {
        Module.ToggleActive.handleVisible.connect(handleToggle)
        Qt.callLater(function() {
            dashWindow = Qt.createQmlObject("Dashboard {}", root);
            plasmoid.activated.connect(function() {
                dashWindow.visible = !dashWindow.visible;
            });
        })


    }

}




