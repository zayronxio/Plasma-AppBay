import QtQuick
pragma Singleton
QtObject {
    signal handleVisible
    signal newTextSearch(string str)
    signal backspace
    signal deleteKey
    signal delateFullText
}
