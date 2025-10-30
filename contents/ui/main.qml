import QtQuick
import QtCore
import QtQuick.Dialogs
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.plasma.core as PlasmaCore
import "Utils.js" as Utils
import "." as Module

PlasmoidItem {
  id: kicker

  Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground | PlasmaCore.Types.ConfigurableBackground
  preferredRepresentation: compactRepresentation

  property bool activeAnimations: true
  property bool searchActive: false
  property bool activeGroup: false
  property var folderAppModel: null
  property int parentGroupIndex
  property bool iconsAnamitaionInitialLoad: false
  property color bgColor: PlasmaCore.Theme.backgroundColor
  property color entryDialogColor: PlasmaCore.Theme.textColor
  property var subModel: []
  property var hiddenApps: []
  property QtObject globalFavorites: rootModel.favoritesModel
  property string listActive: "generalList" // "searchList"

  property var hiddenAppsConfigs: Plasmoid.configuration.hiddenApps


  ListModel {
    id: appsModel
  }

  ListModel {
    id: groupTemporalModel
  }

  Settings {
    id: appBaySettings
    category: "AppBay"
    property var configHiddenApps: []
    property var configSubModelJson: []
  }

  onHiddenAppsConfigsChanged: {
    Utils.findHiddenMissingApps(hiddenAppsConfigs, hiddenApps)
    appBaySettings.configHiddenApps = hiddenAppsConfigs
    hiddenApps = hiddenAppsConfigs
  }


  function saveSubModel() {
    appBaySettings.setValue("configSubModelJson",JSON.stringify(subModel))
  }

  function loadSettings() {
    if (appBaySettings.value("configSubModelJson")) {
      if (appBaySettings.value("configSubModelJson") === "@Invalid()") {
        subModel = []
      } else {
        subModel = JSON.parse(appBaySettings.value("configSubModelJson"))
      }
    } else {
      subModel = []
    }

    if (appBaySettings.value("configHiddenApps")) {
      hiddenApps = appBaySettings.value("configHiddenApps")
    }
  }

  function saveHiddenApps() {
    appBaySettings.configHiddenApps = hiddenApps
  }

  function generateModel() {
    if (!rootModel || rootModel.count === 0) {
      return
    }

    var applicationsModel = rootModel.modelForRow(0)
    if (!applicationsModel) {
      return
    }

    // Limpiamos el modelo antes de regenerarlo
    appsModel.clear()

    // Función de ayuda: verifica si appName está en algún grupo o en hiddenApps
    function isAppHidden(appName, appIndex) {
      // Verificar hiddenApps por nombre
      if (hiddenApps.indexOf(appName) !== -1) {
        return true
      }
      // Verificar subModel por appIndex
      for (var u = 0; u < subModel.length; u++) {
        var group = subModel[u]
        for (var e = 0; e < group.elements.length; e++) {
          if (group.elements[e].appIndex === appIndex) {
            return true
          }
        }
      }
      return false
    }

    // Agregar todas las aplicaciones que NO estén en subModel ni hiddenApps
    for (var appIndex = 0; appIndex < applicationsModel.count; appIndex++) {
      var appIndexObj = applicationsModel.index(appIndex, 0)
      var appName = applicationsModel.data(appIndexObj, Qt.DisplayRole)
      var appIcon = applicationsModel.data(appIndexObj, Qt.DecorationRole)
      var favId = applicationsModel.data(appIndexObj, "favoriteId")

      if (isAppHidden(appName, appIndex)) {
        continue
      }

      appsModel.append({
        display: appName,
        appIndex: appIndex,
        isGroup: false,
        favoriteId: favId,
        decoration: appIcon
      })
    }

    // Agregar los grupos personalizados
    for (var u = 0; u < subModel.length; u++) {
      var group = subModel[u]

      // Comprobación: si el índice es mayor al tamaño actual del modelo, ajustarlo
      var insertIndex = group.indexInModel
      if (insertIndex > appsModel.count) {
        insertIndex = appsModel.count
      }

      appsModel.insert(insertIndex, {
        display: group.displayGrupName,
        isGroup: true,
        modelGroup: group.elements
      })
    }
  }


  // BEGIN Models
  Kicker.RootModel {
    id: rootModel
    // si se llama este model unicamente como rootModel se optiene la lista de las categorias,
    // es necesario filtrar por index, por ejemplo rootModel.modelForRow(0) contiene todos las aplicaciones,
    // pues ese es el index de todas las aplicaciones
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
      if (count > 0) {
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
      const results = ["krunner_services", "krunner_systemsettings", "krunner_sessions",
      "krunner_powerdevil", "calculator", "unitconverter"]
      return results
    }
  }

  compactRepresentation: CompactRepresentation {}

  fullRepresentation: compactRepresentation

  Component.onCompleted: {

    //forceActiveFocus()
    Module.ToggleActive.hiddenAppSignal.connect(saveHiddenApps)
    Module.ToggleActive.delateGroup.connect(function(index) {
      Utils.removeGroup(index)
    })
    loadSettings()
    Plasmoid.configuration.hiddenApps = hiddenApps
    rootModel.refresh()
  }
}
