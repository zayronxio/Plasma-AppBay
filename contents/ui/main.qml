import QtQuick 2.15
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.plasma.core as PlasmaCore
import "." as Module

PlasmoidItem {
  id: kicker

  Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground | PlasmaCore.Types.ConfigurableBackground
  preferredRepresentation: compactRepresentation

  property bool searchActive: false

  property bool activeGroup: false

  property color bgColor: PlasmaCore.Theme.backgroundColor

  property var subModel: [
    {
      displayGrupName: "Mi Grupo",
      indexInModel: 6,
      isGroup: true,
      elements: [
        {
          display: "Okular",
          decoration: "okular",
          appIndex: 28
        },
        {
          display: "Firefox",
          decoration: "firefox",
          appIndex: 1
        }
      ]
    }
  ]

  property QtObject globalFavorites: rootModel.favoritesModel

  property string listActive: "generalList" // "searchList"

  ListModel {
    id: appsModel
  }

  Keys.onPressed: (event) => {
    if (event.key === Qt.Key_Escape) {
      if (activeGroup) {
        activeGroup = false
        event.accepted = true
      } else if (searchActive) {
        searchActive = false
        event.accepted = true
      } else {
        Module.ToggleActive.delateFullText()
        searchActive = false
        Module.ToggleActive.handleVisible()
        event.accepted = true
      }

    }
    else if (event.key === Qt.Key_Backspace) {
      if (searchActive) {
        Module.ToggleActive.backspace()
        event.accepted = true
      }
    }
    else if (event.key === Qt.Key_Delete) {
      if (searchActive) {
        Module.ToggleActive.deleteKey()
        event.accepted = true
      }
    }
    else if (event.text !== "" && !event.ctrl && !event.alt && !event.meta) {
      event.accepted = true;
      searchActive = true
      Module.ToggleActive.newTextSearch(event.text)
    }
    else {
      event.accepted = false
    }
  }

  function generateModel() {
    if (!rootModel || rootModel.count === 0) {
      return
    }

    var applicationsModel = rootModel.modelForRow(0)
    if (!applicationsModel) {
      return
    }

    // 💡 Limpiamos el modelo antes de regenerarlo
    appsModel.clear()

    // --- Agregar todas las aplicaciones ---
    for (var appIndex = 0; appIndex < applicationsModel.count; appIndex++) {
      var appIndexObj = applicationsModel.index(appIndex, 0)
      var appName = applicationsModel.data(appIndexObj, Qt.DisplayRole)
      var appIcon = applicationsModel.data(appIndexObj, Qt.DecorationRole)

      appsModel.append({
        display: appName,
        appIndex: appIndex,
        isGroup: false,
        decoration: appIcon
      })
    }

    // --- Agregar los grupos personalizados ---
    for (var u = 0; u < subModel.length; u++) {
      var group = subModel[u]
      appsModel.insert(group.indexInModel, {
        display: group.displayGrupName,
        isGroup: true,
        modelGroup: group.elements
      })
    }
  }


  //BEGIN Models
  Kicker.RootModel {
    id: rootModel // si se llama este model unicamente como rootModel se optiene la lista de las categorias, es necesario filtrar por index, por ejemplo rootModel.modelForRow(0) contiene todos las aplicaciones, pues ese es el index de todas las aplicaciones
    autoPopulate: false

    appNameFormat: 0
    flat: true
    sorted: true
    showSeparators: false
    appletInterface: kicker
    showAllApps: true
    showRecentApps: false
    showRecentDocs: false
    showPowerSession: false

    onCountChanged: {
      if (count > 0){
        generateModel()
      }

    }

    Component.onCompleted: {
      favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + Plasmoid.id)
    }

  }

  Kicker.RunnerModel {
    id: runnerModel

    appletInterface: kicker

    favoritesModel: globalFavorites

    runners: {
      const results = ["krunner_services",
      "krunner_systemsettings",
      "krunner_sessions",
      "krunner_powerdevil",
      "calculator",
      "unitconverter"];
      return results;
    }
  }

  compactRepresentation: CompactRepresentation {
  }
  fullRepresentation: compactRepresentation


  Component.onCompleted: {
    forceActiveFocus()
    rootModel.refresh()
  }
}
