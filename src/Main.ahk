; Main.ahk — WordMeaning entry point.
; Select a single word anywhere (browser, PDF, Word) → definition popup at cursor.
#Requires AutoHotkey v2.0
#SingleInstance Force

#Include Config.ahk
#Include Dictionary.ahk
#Include Popup.ahk
#Include SelectionWatcher.ahk
#Include FocusWatcher.ahk

enabled := true

InitTray()
SelectionWatcher.Start(OnSelection, DismissPopup)   ; onPress -> hide (click anywhere dismisses)
FocusWatcher.Start(DismissPopup)                    ; window/app switch dismisses

DismissPopup() {
    Popup.Hide()
}

OnSelection(text) {
    global enabled
    if !enabled
        return
    ; Single words only — sentences/fragments are ignored silently.
    if !RegExMatch(text, Config.WordPattern)
        return

    result := Dictionary.Lookup(text)
    if result.ok {
        header := result.word . (result.partOfSpeech != "" ? " (" . result.partOfSpeech . ")" : "")
        Popup.Show(header . "`n" . result.definition)
    } else if (result.error != "not a single word") {
        Popup.Show(result.word . "`n" . result.error)
    }
}

InitTray() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Enabled", ToggleEnabled)
    A_TrayMenu.Check("Enabled")
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    A_IconTip := "WordMeaning — select a word to see its meaning"
}

ToggleEnabled(*) {
    global enabled
    enabled := !enabled
    if enabled
        A_TrayMenu.Check("Enabled")
    else {
        A_TrayMenu.Uncheck("Enabled")
        Popup.Hide()
    }
}
