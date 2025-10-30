import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.kwindowsystem 1.0
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker 0.1 as Kicker

Kicker.DashboardWindow {
    id: dashboard

    //visualParent: root

    backgroundColor: "transparent"
    //flags: Qt.Window | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.ToolTip

    onKeyEscapePressed: {
        listActive = "generalList"
        if (searchActive) {
            searchEntry.text = ""
            //listActive = "generalList"
        } else if (activeGroup){
            activeGroup = false
        } else {
            toggle()
        }
    }

    Rectangle {
        id: background

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
                        searchEntry.forceActiveFocus()
                    })
                } else {
                    background.opacity = 0.0
                }
            }
        }

        // SearchEntry en posición fija arriba
        SearchEntry {
            id: searchEntry
            //focus: true
            height: 48
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: 30
            }
            width: Math.min(parent.width - 60, 400) // Ancho máximo
        }

        PowerActions {
            id: powerActions
            anchors.verticalCenter: searchEntry.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 16
        }

        // AppList ocupando el resto del espacio
        AppList {
            id: appList
            height: parent.height - searchEntry.height
            width:  parent.width
            anchors {
                top: searchEntry.bottom
                topMargin: 20
                horizontalCenter: parent.horizontalCenter
            }
            //focus: true
            visible: true

            onOpenGridApp: function (ID) {
                console.log("abriendo app:", ID)
                var applicationsModel = rootModel.modelForRow(0)
                if (applicationsModel) {
                    applicationsModel.trigger(ID, "", null)
                    dashboard.visible = false
                }
            }
        }

        FavorirtesDock {
            id: favorirtesDock
            sizeIconDock: 56
            spacingMargin: 8
            visible: Plasmoid.configuration.dockF
            maxIconsInDock: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
