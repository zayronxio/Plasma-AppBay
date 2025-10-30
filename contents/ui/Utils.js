/*/
updatesubModel(name,newArrayModel) funcion para actulizar el array subModel y cargar los datos en settigs
removeGroup(index) funcion para eliminar un grupo completo
removeAppOfGroup(targetIndex, appName) function para eliminar una app de un grupo
removeByAppIndex(appIndex) function para eliminar una app de el model de uso general (appsModel), el model que proporciona los datos es rootModel y no es editable
/*/

function toArray(listModel) {
    var arr = []
    if (!listModel)
        return arr

        // Si es un QQmlListModel, recorre sus elementos
        if (listModel.count !== undefined) {
            for (var i = 0; i < listModel.count; i++) {
                arr.push(listModel.get(i))
            }
        }
        // Si ya es array, simplemente devuélvelo
        else if (Array.isArray(listModel)) {
            arr = listModel
        }

        return arr
}

function removeByAppIndex(appIndex) {
    for (var i = 0; i < appsModel.count; i++) {
        if (appsModel.get(i).appIndex === appIndex) {
            appsModel.remove(i, 1)
            break
        }
    }
}

function updatesubModel(name,newArrayModel) {
    for (var i = 0; i < subModel.length; i++) {
        var subArray = subModel[i].elements
        for (var t = 0; t < subArray.length; t++) {
            console.log(subArray[t].display,name)
            if (subArray[t].display === name) {
                subModel[i].elements = cloneToPureArray(newArrayModel)
                saveSubModel()
                break
            }
        }
    }

}

function cloneToPureArray(array) {
    var result = []
    for (var i = 0; i < array.length; i++) {
        var item = array[i]
        result.push({
            display: item.display,
            decoration: item.decoration,
            appIndex: item.appIndex
        })
    }
    return result
}

function findHiddenMissingApps(stringList, array) {
    let missing = []

    for (let i = 0; i < array.length; i++) {
        let app = array[i]
        if (stringList.indexOf(app) === -1) {
            missing.push(app)
        }
    }

    for (var w = 0; w < missing.length; w++){
        addAppAppModel(missing[w])
    }
}

function addAppAppModel(appName){
    var applicationsModel = rootModel.modelForRow(0)
    for (var j = 0; j < applicationsModel.count; j++) {

        var appIndexObj = applicationsModel.index(j, 0)
        var nameInModel = applicationsModel.data(appIndexObj, Qt.DisplayRole)
        if (nameInModel === appName) {
            if (j < appsModel.count) {
                appsModel.insert(j, {
                    display: nameInModel,
                    appIndex: j,
                    decoration: applicationsModel.data(appIndexObj, Qt.DecorationRole),
                    isGroup: false,
                    favoriteId: ""
                })
            } else {
                appsModel.insert(j, {
                    display: nameInModel,
                    appIndex: j,
                    decoration: applicationsModel.data(appIndexObj, Qt.DecorationRole),
                    isGroup: false,
                    favoriteId: ""
                })
            }
            break;
        }
    }
}

function removeGroup(index) {
    // el index debe ser en funcion de appsModel
    var target = appsModel.get(index)

    for (var h = 0; h < subModel.length; h++) {
        if (target.display === subModel[h].displayGrupName) {
            subModel.splice(h,1)
            saveSubModel()
            break;
        }
    }

    var arrayModelGroup = toArray(target.modelGroup)

    var arrayOfNames = []

    for (var r = 0; r < arrayModelGroup.length; r++) {
        arrayOfNames.push(arrayModelGroup[r].display)
    }

    appsModel.remove(index) // se elimina el grupo completo antes de agregar las nuevas app, ya que de hacerse despues el index puede cambiar

    for (var g = 0; g < arrayOfNames.length; g++) {
        addAppAppModel(arrayOfNames[g])
    }


}

function removeAppOfGroup(targetIndex, appName) {

    var target = appsModel.get(targetIndex)
    var arrayModelGroup = toArray(target.modelGroup)

    if (arrayModelGroup.length > 1) {
        // Buscar el índice del elemento a eliminar
        var indexToRemove = -1
        for (var i = 0; i < arrayModelGroup.length; i++) {
            if (arrayModelGroup[i].display === appName) {
                indexToRemove = i
                break
            }
        }

        if (indexToRemove !== -1) {
            // Crear nuevo array sin el elemento
            var newArrayModel = []
            for (var j = 0; j < arrayModelGroup.length; j++) {
                if (j !== indexToRemove) {

                    newArrayModel.push(arrayModelGroup[j])

                }
            }
            updatesubModel(appName, newArrayModel)

            // llena model temporal para matener el grupo visible
            groupTemporalModel.clear()
            for (var e =0; e < newArrayModel.length; e++){
                groupTemporalModel.append({
                    display: newArrayModel[e].display,
                    decoration: newArrayModel[e].decoration,
                    isGrupo: false,
                    appIndex: newArrayModel[e].appIndex
                })
            }
            folderAppModel = groupTemporalModel //actualiza model del grupo
            /*/*/
            appsModel.set(targetIndex, {
                modelGroup: newArrayModel,
                display: target.display,
                isGroup: true
            })

            addAppAppModel(appName)

        }

    } else {
        activeGroup = false
        removeGroup(targetIndex)
    }
}

function renameGroup(index,newName) {
    var name = appsModel.get(index).display
    console.log(name,subModel.length)
    for (var i = 0; i < subModel.length; i++) {
        if (subModel[i].displayGrupName === name) {
            subModel[i].displayGrupName = newName
            saveSubModel()
            break
        }
    }

    appsModel.set(index, { "display": newName })

}
