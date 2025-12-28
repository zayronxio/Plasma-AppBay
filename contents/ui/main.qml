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

  property int oldPage
  property int currentPage: 0

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
    if (!rootModel || rootModel.count === 0)
      return

      var applicationsModel = rootModel.modelForRow(0)
      if (!applicationsModel)
        return

        appsModel.clear()

        /* ==============================
         * 1️⃣ Crear mapas de apps actuales
         * ============================== */

        var appMapByName = {}
        var appMapByStorageId = {}

        for (var i = 0; i < applicationsModel.count; i++) {
          var idx = applicationsModel.index(i, 0)
          var name = applicationsModel.data(idx, Qt.DisplayRole)
          var icon = applicationsModel.data(idx, Qt.DecorationRole)
          var storageId = applicationsModel.data(idx, "storageId")

          var appData = {
            appIndex: i,
            display: name,
            decoration: icon,
            favoriteId: storageId
          }

          appMapByName[name] = appData

          if (storageId)
            appMapByStorageId[storageId] = appData
        }

        /* ==================================
         * 2️⃣ Resolver app desde configuración
         * ================================== */

        function resolveApp(element) {
          // Prioridad 1: storageId
          if (element.favoriteId &&
            appMapByStorageId[element.favoriteId]) {
            return appMapByStorageId[element.favoriteId]
            }

            // Prioridad 2: nombre visible
            if (appMapByName[element.display]) {
              return appMapByName[element.display]
            }

            // Fallback: appIndex antiguo
            if (element.appIndex !== undefined &&
              element.appIndex < applicationsModel.count) {

              var idx = applicationsModel.index(element.appIndex, 0)
              var name = applicationsModel.data(idx, Qt.DisplayRole)

              if (name === element.display) {
                return {
                  appIndex: element.appIndex,
                  display: name,
                  decoration: applicationsModel.data(idx, Qt.DecorationRole),
                  favoriteId: applicationsModel.data(idx, "storageId")
                }
              }
              }

              return null
        }

        /* =========================================
         * 3️⃣ Verificar si una app está oculta/grupo
         * ========================================= */

        function isAppHidden(appName, appIndex) {
          // hiddenApps por nombre
          if (hiddenApps.indexOf(appName) !== -1)
            return true

            // grupos
            for (var g = 0; g < subModel.length; g++) {
              var group = subModel[g]
              for (var e = 0; e < group.elements.length; e++) {
                var el = group.elements[e]
                if (el.display === appName)
                  return true
              }
            }
            return false
        }

        /* ==============================
         * 4️⃣ Apps normales (no agrupadas)
         * ============================== */

        for (var a = 0; a < applicationsModel.count; a++) {
          var idx = applicationsModel.index(a, 0)
          var name = applicationsModel.data(idx, Qt.DisplayRole)

          if (isAppHidden(name, a))
            continue

            appsModel.append({
              display: name,
              appIndex: a,
              isGroup: false,
              favoriteId: applicationsModel.data(idx, "storageId"),
                             decoration: applicationsModel.data(idx, Qt.DecorationRole)
            })
        }

        /* ==========================
         * 5️⃣ Insertar grupos
         * ========================== */

        for (var u = 0; u < subModel.length; u++) {
          var group = subModel[u]
          var resolvedElements = []

          for (var e = 0; e < group.elements.length; e++) {
            var resolved = resolveApp(group.elements[e])
            if (resolved) {
              resolvedElements.push({
                display: resolved.display,
                decoration: resolved.decoration,
                appIndex: resolved.appIndex,
                favoriteId: resolved.favoriteId
              })
            }
          }

          // No insertar grupos vacíos
          if (resolvedElements.length === 0)
            continue

            var insertIndex = group.indexInModel
            if (insertIndex > appsModel.count)
              insertIndex = appsModel.count

              appsModel.insert(insertIndex, {
                display: group.displayGrupName,
                isGroup: true,
                modelGroup: resolvedElements
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
    Module.ToggleActive.hiddenAppSignal.connect(saveHiddenApps)
    Module.ToggleActive.delateGroup.connect(function(index) {
      Utils.removeGroup(index)
    })
    loadSettings()
    Plasmoid.configuration.hiddenApps = hiddenApps
    rootModel.refresh()
  }
}
