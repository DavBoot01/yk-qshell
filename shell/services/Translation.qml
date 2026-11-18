pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Translation — i18n via JSON dictionaries in translations/<locale>.json.
//
// Keys are the English source strings; a missing key falls back to the key
// itself, so untranslated text is always readable.
//
//   Text { text: Translation.tr("Settings") }
//
// Set `languageCode` to a locale ("it_IT") or "auto" to follow the system
// locale. Changing it reloads the dictionary; every binding calling tr()
// re-evaluates because tr() reads `_dict`.
Singleton {
    id: root

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    property bool   loading: false
    property bool   ready:   false
    property string error:   ""

    function initialize(): void {
        if (loading || ready) return
        loading = true
        _file.path = Qt.resolvedUrl("../translations/" + root.effectiveCode + ".json")
    }

    Component.onCompleted: initialize()

    // ── Configuration ─────────────────────────────────────────────────────────
    property string languageCode: "auto"
    readonly property string effectiveCode:
        languageCode === "auto" ? Qt.locale().name : languageCode

    onEffectiveCodeChanged: {
        // Explicit reset: new language means a new dictionary.
        ready = false
        loading = false
        initialize()
    }

    // ── API ───────────────────────────────────────────────────────────────────
    property var _dict: ({})

    function tr(key: string): string {
        const v = root._dict[key]
        return v !== undefined ? v : key
    }

    // ── Loader ────────────────────────────────────────────────────────────────
    FileView {
        id: _file
        onLoaded: {
            try {
                root._dict = JSON.parse(_file.text())
                root.error = ""
            } catch (e) {
                root._dict = ({})
                root.error = "Invalid translation file: " + e
            }
            root.loading = false
            root.ready = true
        }
        onLoadFailed: {
            // Unknown locale: keep English keys as fallback.
            root._dict = ({})
            root.error = "No translation for " + root.effectiveCode
            root.loading = false
            root.ready = true
        }
    }
}
