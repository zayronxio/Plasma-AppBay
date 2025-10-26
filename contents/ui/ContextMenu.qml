import QtQuick
import org.kde.plasma.extras as PlasmaExtras
import "." as Module

Item {
    id: root

    property QtObject menu: contextMenuComponent.createObject(root);

    property Item visualParent
    property int index

    //menu = contextMenuComponent.createObject(root);

    function open(x, y,idx) {
         menu.open(x, y);
         index = idx
    }

    function hiddeApp() {
        for (var f = 0; f < appsModel.count; f++){
            if (appsModel.get(f).appIndex === index) {
                hiddenApps.push(appsModel.get(f).display)
                appsModel.remove(f,1)
            }
        }
    }
    Component {
        id: contextMenuComponent

        PlasmaExtras.Menu {
            visualParent: root.visualParent
            PlasmaExtras.MenuItem {
                id: submenuItem
                text: "Hidden App"
                icon: "configure"
                onClicked: {
                    hiddeApp()
                }
            }
        }
    }
}

