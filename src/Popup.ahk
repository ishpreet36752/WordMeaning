; Popup.ahk — definition tooltip at cursor. Auto-hides; any new lookup replaces it.
#Requires AutoHotkey v2.0

class Popup {
    ; Single bound instance so SetTimer resets/deletes the SAME timer each call —
    ; a fresh BoundFunc per call would leak stale timers that hide newer popups early.
    static _hideFn := ""

    static Show(text) {
        if (Popup._hideFn == "")
            Popup._hideFn := ObjBindMethod(Popup, "_Hide")
        MouseGetPos(&x, &y)
        ToolTip(text, x + 12, y + 16)
        SetTimer(Popup._hideFn, 0)                          ; cancel pending hide
        SetTimer(Popup._hideFn, -Config.TooltipTimeoutMs)   ; run once
    }

    static Hide() {
        Popup._Hide()
    }

    static _Hide(*) {
        ToolTip()
    }
}
