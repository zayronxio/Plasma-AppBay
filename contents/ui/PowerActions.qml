import QtQuick
import org.kde.plasma.private.sessions as Sessions
import org.kde.kirigami as Kirigami

Item {
    width: wrapperActionsButtons.width
    height: wrapperActionsButtons.height

    property int iconsSize: 24
    property int spacingRow: 8

    Sessions.SessionManagement {
        id: sm
    }

    Sessions.SessionsModel {
        id: sessionsModel
    }

    Row {
        id: wrapperActionsButtons
        width: (spacingRow*3) + (iconsSize*4)
        height: iconsSize
        spacing: spacingRow

        // Botón Apagar
        Kirigami.Icon {
            id: shutdownButton
            width: iconsSize
            height: iconsSize
            source: "system-shutdown"   // Icono de apagar
            MouseArea {
                anchors.fill: parent
                onClicked: sm.requestShutdown()
            }
        }

        // Botón Reiniciar
        Kirigami.Icon {
            id: restartButton
            width: iconsSize
            height: iconsSize
            source: "system-reboot"   // Icono de reinicio
            MouseArea {
                anchors.fill: parent
                onClicked: sm.requestRestart()
            }
        }

        // Botón Bloquear
        Kirigami.Icon {
            id: lockButton
            width: iconsSize
            height: iconsSize
            source: "system-lock-screen"   // Icono de bloqueo
            MouseArea {
                anchors.fill: parent
                onClicked: sessionsModel.startNewSession(sessionsModel.shouldLock)
            }
        }

        // Botón Cerrar Sesión
        Kirigami.Icon {
            id: logoutButton
            width: iconsSize
            height: iconsSize
            source: "system-log-out"   // Icono de cerrar sesión
            MouseArea {
                anchors.fill: parent
                onClicked: sm.requestLogoutPrompt()
            }
        }
    }
}
