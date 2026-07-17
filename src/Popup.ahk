; Popup.ahk — definition tooltip at cursor. Auto-hides; any new lookup replaces it.
#Requires AutoHotkey v2.0

class Popup {
    static Show(text) {
        MouseGetPos(&x, &y)
        ToolTip(text, x + 12, y + 16)
        SetTimer(Popup._Hide, -Config.TooltipTimeoutMs)
    }

    static Hide() {
        Popup._Hide()
    }

    static _Hide(*) {
        ToolTip()
    }
}
