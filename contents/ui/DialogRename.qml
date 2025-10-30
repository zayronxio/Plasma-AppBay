/*
 *  SPDX-FileCopyrightText: zayronxio
 *  SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Dialogs

MessageDialog {
    id: rename
    text: "Rename Group?"
    buttons: MessageDialog.Ok | MessageDialog.Cancel
    Item {

    }
    onButtonClicked: function (button, role) {
        switch (button) {
            case MessageDialog.Ok:
                listMultimedia.startScan()
                break;
        }
    }
}
