import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.kwindowsystem 1.0
import org.kde.plasma.private.kicker 0.1 as Kicker

Kicker.DashboardWindow  {
    id: dashboard

    visualParent: root

    backgroundColor: "transparent"
    flags: Qt.Window | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.ToolTip


    Rectangle {
        id: background

        property color bgColor: PlasmaCore.Theme.backgroundColor

        anchors.fill: parent
        color: Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.6)
        opacity: 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 400
                easing.type: Easing.InOutQuad
            }
        }

        Connections {
            target: dashboard
            function onVisibleChanged() {
                if (dashboard.visible) {
                    background.opacity = 1.0
                    Qt.callLater(function() {
                        appList.forceActiveFocus()
                    })
                } else {
                    background.opacity = 0.0
                }
            }
        }

        // contenido
        AppList {
            id: appList
            anchors.fill: parent
            focus: true
            onOpenGridApp: function (ID) {
                console.log("abriendo app:", ID)
                var applicationsModel = rootModel.modelForRow(0)
                if (applicationsModel) {
                    applicationsModel.trigger(ID, "", null)
                    dashboard.visible = false
                }
            }
        }
    }
}
