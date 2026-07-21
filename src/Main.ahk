; Main.ahk — WordMeaning entry point.
; Select a single word anywhere (browser, PDF, Word) → definition popup at cursor.
#Requires AutoHotkey v2.0
#SingleInstance Force

#Include Config.ahk
#Include Dictionary.ahk
#Include Popup.ahk
#Include SelectionWatcher.ahk
#Include FocusWatcher.ahk
#Include Startup.ahk

enabled := true
lastWord := ""      ; word in the current popup — target of the web-search hotkey

SetTrayIcon()
InitTray()
InitWebSearchHotkey()
SelectionWatcher.Start(OnSelection, DismissPopup)   ; onPress -> hide (click anywhere dismisses)
FocusWatcher.Start(DismissPopup)                    ; window/app switch dismisses

DismissPopup() {
    Popup.Hide()
}

OnSelection(text) {
    global enabled, lastWord
    if !enabled
        return
    ; Single words only — sentences/fragments are ignored silently.
    if !RegExMatch(text, Config.WordPattern)
        return

    result := Dictionary.Lookup(text)
    if result.ok {
        lastWord := result.word
        header := result.word . (result.partOfSpeech != "" ? " (" . result.partOfSpeech . ")" : "")
        ; Two senses are numbered; a lone sense is not, so the common case stays terse.
        body := result.altDefinition != ""
            ? "1. " . result.definition . "`n2. " . result.altDefinition
            : result.definition
        if (result.example != "")
            body .= "`n" . '"' . result.example . '"'
        Popup.Show(header . "`n" . body)
    } else if (result.error != "not a single word") {
        lastWord := result.word
        ; Dead end — offer the browser. Never open it unasked: that would steal focus
        ; and hand the word to a search engine the user did not choose to involve.
        Popup.Show(result.word . "`n" . result.error . "`n" . Config.WebSearchHint)
    }
}

; The hotkey exists only while a popup is on screen, so it cannot shadow the same
; combination in the app the user is reading.
InitWebSearchHotkey() {
    HotIf (*) => Popup.IsVisible()
    Hotkey(Config.WebSearchHotkey, OpenWebSearch)
    HotIf
}

OpenWebSearch(*) {
    global lastWord
    Popup.Hide()
    if (lastWord == "")
        return
    try Run(Config.WebSearchUrl . Dictionary.UrlEncode(lastWord))
}

; Compiled builds carry the icon embedded (Ahk2Exe /icon) and the tray uses it
; automatically. When run as a raw .ahk during development, load it from assets.
SetTrayIcon() {
    if A_IsCompiled
        return
    iconPath := A_ScriptDir "\" Config.IconRelPath
    if FileExist(iconPath)
        TraySetIcon(iconPath)
}

InitTray() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Enabled", ToggleEnabled)
    A_TrayMenu.Check("Enabled")
    A_TrayMenu.Add("Start with Windows", ToggleStartup)
    if Startup.IsEnabled()
        A_TrayMenu.Check("Start with Windows")
    A_TrayMenu.Add()                              ; separator
    A_TrayMenu.Add("About", ShowAbout)            ; carries the CC BY-SA attribution
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    A_IconTip := Config.AppName " — select a word to see its meaning"
}

; The primary source is CC BY-SA 4.0 and requires visible attribution.
ShowAbout(*) {
    MsgBox(Config.AttributionText, Config.AppName, "Iconi")
}

ToggleStartup(*) {
    if Startup.Toggle()
        A_TrayMenu.Check("Start with Windows")
    else
        A_TrayMenu.Uncheck("Start with Windows")
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
