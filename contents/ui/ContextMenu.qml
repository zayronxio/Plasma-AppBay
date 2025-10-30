import QtQuick
import org.kde.plasma.extras as PlasmaExtras
import "." as Module
import "Utils.js" as Utils

Item {
    id: root

    property QtObject menu: contextMenuComponent.createObject(root);

    property Item visualParent
    property int indexInAppsModel
    property bool isGruop
    property int appIndex  // El índice en el modelo original
    property string currentName: ""  // Agregar esta propiedad


    function open(x, y, idx) {
        menu.open(x, y);
        appIndex = idx
    }

    function hiddeApp() {
        for (var f = 0; f < appsModel.count; f++){
            if (appsModel.get(f).appIndex === appIndex) {
                hiddenApps.push(appsModel.get(f).display)
                appsModel.remove(f,1)
                Module.ToggleActive.hiddenAppSignal()
                break
            }
        }
    }

    function addToFavorites() {
        // Método alternativo: obtener desde appsModel

        // Si no está en appsModel, obtener del modelo original
        if (!rootModel || rootModel.count === 0) {
            console.warn("rootModel no está disponible")
            return
        }

        var applicationsModel = rootModel.modelForRow(0)
        if (!applicationsModel) {
            console.warn("No se pudo obtener applicationsModel")
            return
        }

        var appIndexObj = applicationsModel.index(appIndex, 0)
        var favoriteId = applicationsModel.data(appIndexObj, Kicker.UrlRole)

        if (favoriteId && favoriteId.length > 0) {
            console.log("Adding favorite from rootModel:", favoriteId)
            rootModel.favoritesModel.addFavorite(favoriteId)
        } else {
            console.warn("No favoriteId válido encontrado para appIndex:", appIndex)
        }
    }

    /*/Kirigami.PromptDialog {
        id: renameDialog
        title: "Rename Group"


    }/*/

    Component {
        id: contextMenuComponent

        PlasmaExtras.Menu {
            visualParent: root.visualParent

            PlasmaExtras.MenuItem {
                text: "Hidden App"
                icon: "view-hidden-symbolic"
                visible: !isGruop
                onClicked: {
                    hiddeApp()
                }
            }

            PlasmaExtras.MenuItem {
                text: "Add to Favorites"
                icon: "favorite"
                visible: !isGruop
                onClicked: {
                    addToFavorites()
                }
            }
            PlasmaExtras.MenuItem {
                text: "Rename Group"
                icon: "entry-edit-symbolic"
                visible: isGruop
                onClicked: {
                    nameActiveGroup = currentName
                    activeIndex = indexInAppsModel
                    rename.open()
                }
            }
            PlasmaExtras.MenuItem {
                text: "Delate Group"
                icon: "remove-symbolic"
                visible: isGruop
                onClicked: {
                    Module.ToggleActive.delateGroup(indexInAppsModel)
                }
            }
        }
    }
}
