; FocusWatcher.ahk — fires a callback when the active (foreground) window changes.
; Implemented by polling the active window id on a timer: simple, no DllCall/OS
; callback, and reliably catches Alt+Tab and switching to another app.
; Note: switching TABS inside one browser is NOT a window change (same window);
; that case is covered by the click-to-dismiss path in SelectionWatcher.
#Requires AutoHotkey v2.0

class FocusWatcher {
    static _onChange := ""
    static _lastWin := 0
    static _tickFn := ""      ; cached BoundFunc so SetTimer targets the same timer

    static Start(onChange) {
        FocusWatcher._onChange := onChange
        FocusWatcher._lastWin := WinExist("A")
        FocusWatcher._tickFn := FocusWatcher._Tick.Bind(FocusWatcher)
        SetTimer(FocusWatcher._tickFn, Config.FocusPollMs)
    }

    static Stop() {
        if (FocusWatcher._tickFn != "")
            SetTimer(FocusWatcher._tickFn, 0)
    }

    static _Tick(*) {
        cur := WinExist("A")
        if (cur != FocusWatcher._lastWin) {
            FocusWatcher._lastWin := cur
            if (FocusWatcher._onChange != "")
                FocusWatcher._onChange.Call()
        }
    }
}
