; SelectionWatcher.ahk — detects text selection (drag or double-click) in any app
; and captures it via a clipboard-preserving Ctrl+C probe.
#Requires AutoHotkey v2.0

class SelectionWatcher {
    static _onSelect := ""
    static _pressX := 0
    static _pressY := 0
    static _lastClickTick := 0

    ; callback: func(text) — called with captured selection text (may be multi-word; caller filters)
    static Start(callback) {
        SelectionWatcher._onSelect := callback
        HotIf
        Hotkey("~LButton", SelectionWatcher._OnPress.Bind(SelectionWatcher))
        Hotkey("~LButton Up", SelectionWatcher._OnRelease.Bind(SelectionWatcher))
    }

    static _OnPress(*) {
        MouseGetPos(&x, &y)
        SelectionWatcher._pressX := x
        SelectionWatcher._pressY := y
    }

    static _OnRelease(*) {
        MouseGetPos(&x, &y)
        dragged := Abs(x - SelectionWatcher._pressX) > Config.DragThresholdPx
                || Abs(y - SelectionWatcher._pressY) > Config.DragThresholdPx

        now := A_TickCount
        isDoubleClick := (now - SelectionWatcher._lastClickTick) < Config.DoubleClickMs
        SelectionWatcher._lastClickTick := now

        if !(dragged || isDoubleClick)
            return

        ; Double-click selection needs a beat for the app to apply word-select.
        if isDoubleClick
            Sleep(50)

        text := SelectionWatcher._CaptureSelection()
        if (text != "" && SelectionWatcher._onSelect != "")
            SelectionWatcher._onSelect.Call(text)
    }

    ; Copies current selection while preserving the user's clipboard.
    ; Returns "" if nothing was selected (e.g. password fields, empty click).
    static _CaptureSelection() {
        saved := ClipboardAll()
        A_Clipboard := ""
        Send("^c")
        captured := ""
        if ClipWait(Config.ClipWaitSec)
            captured := A_Clipboard
        A_Clipboard := saved   ; always restore, even on failure
        return Trim(captured, " `t`r`n")
    }
}
