; Popup.ahk — definition tooltip at cursor. Auto-hides; any new lookup replaces it.
; The native ToolTip only breaks on newlines, so long text becomes one very wide
; line — we word-wrap to Config.PopupWrapWidth to keep the popup a readable column.
#Requires AutoHotkey v2.0

class Popup {
    ; Single bound instance so SetTimer resets/deletes the SAME timer each call —
    ; a fresh BoundFunc per call would leak stale timers that hide newer popups early.
    static _hideFn := ""
    static _showing := false   ; gates the web-search hotkey (live only while a popup is up)

    static Show(text) {
        if (Popup._hideFn == "")
            Popup._hideFn := ObjBindMethod(Popup, "_Hide")
        text := Popup._Wrap(text, Config.PopupWrapWidth)
        MouseGetPos(&x, &y)
        ToolTip(text, x + 12, y + 16)
        Popup._showing := true
        SetTimer(Popup._hideFn, 0)                          ; cancel pending hide
        SetTimer(Popup._hideFn, -Config.TooltipTimeoutMs)   ; run once
    }

    static Hide() {
        Popup._Hide()
    }

    static _Hide(*) {
        ToolTip()
        Popup._showing := false
    }

    static IsVisible() {
        return Popup._showing
    }

    ; Wrap each existing line to at most `width` characters, breaking at spaces.
    static _Wrap(text, width) {
        out := ""
        for i, line in StrSplit(text, "`n") {
            if (i > 1)
                out .= "`n"
            out .= Popup._WrapLine(line, width)
        }
        return out
    }

    static _WrapLine(line, width) {
        result := ""
        cur := ""
        for word in StrSplit(line, " ") {
            if (cur == "")
                cur := word
            else if (StrLen(cur) + 1 + StrLen(word) <= width)
                cur .= " " . word
            else {
                result .= (result == "" ? "" : "`n") . cur
                cur := word
            }
        }
        if (cur != "")
            result .= (result == "" ? "" : "`n") . cur
        return result
    }
}
