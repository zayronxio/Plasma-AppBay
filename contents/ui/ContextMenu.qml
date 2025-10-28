import QtQuick
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.kicker 0.1 as Kicker
import "." as Module

Item {
    id: root

    property QtObject menu: contextMenuComponent.createObject(root);

    property Item visualParent
    property int appIndex  // El índice en el modelo original


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

        console.log("kicker UrlRole",applicationsModel.data(appIndexObj, Kicker.UrlRole))
        console.log("Qt UrlRole",applicationsModel.data(appIndexObj, Qt.UrlRole))
        console.log("UrlRole",applicationsModel.data(appIndexObj, "UrlRole"))
        console.log("Url",applicationsModel.data(appIndexObj, "Url"))
        console.log("url",applicationsModel.data(appIndexObj, "url"))
        console.log("url",applicationsModel.data(appIndexObj, "url"))
        console.log("FavoriteId",applicationsModel.data(appIndexObj, "FavoriteId"))
        console.log("favoriteId",applicationsModel.data(appIndexObj, "favoriteId"))
        console.log("favoriteid",applicationsModel.data(appIndexObj, "favoriteid"))
        console.log("Kicker.FavoriteIdRole",applicationsModel.data(appIndexObj, Kicker.FavoriteIdRole))
        console.log("Qt.FavoriteIdRole",applicationsModel.data(appIndexObj, Qt.FavoriteIdRole))

        if (favoriteId && favoriteId.length > 0) {
            console.log("Adding favorite from rootModel:", favoriteId)
            rootModel.favoritesModel.addFavorite(favoriteId)
        } else {
            console.warn("No favoriteId válido encontrado para appIndex:", appIndex)
        }
    }


    Component {
        id: contextMenuComponent

        PlasmaExtras.Menu {
            visualParent: root.visualParent

            PlasmaExtras.MenuItem {
                text: "Hidden App"
                icon: "configure"
                onClicked: {
                    hiddeApp()
                }
            }

            PlasmaExtras.MenuItem {
                text: "Add to Favorites"
                icon: "favorite"
                onClicked: {
                    addToFavorites()
                }
            }
        }
    }
}
