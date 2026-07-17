; FocusWatcher.ahk — fires a callback when the OS foreground window changes
; (Alt+Tab, clicking another app). Used to dismiss the popup on window switch.
; Note: switching TABS inside one browser is NOT a foreground change (same window);
; that case is covered by the click-to-dismiss path in SelectionWatcher.
#Requires AutoHotkey v2.0

class FocusWatcher {
    static _onChange := ""
    static _hook := 0
    static _cb := 0

    ; EVENT_SYSTEM_FOREGROUND = 0x0003
    ; WINEVENT_OUTOFCONTEXT = 0x0000, WINEVENT_SKIPOWNPROCESS = 0x0002
    static Start(onChange) {
        FocusWatcher._onChange := onChange
        FocusWatcher._cb := CallbackCreate(FocusWatcher._Proc, "", 7)
        FocusWatcher._hook := DllCall("SetWinEventHook"
            , "UInt", 0x0003, "UInt", 0x0003
            , "Ptr", 0
            , "Ptr", FocusWatcher._cb
            , "UInt", 0, "UInt", 0
            , "UInt", 0x0002
            , "Ptr")
    }

    static Stop() {
        if FocusWatcher._hook {
            DllCall("UnhookWinEvent", "Ptr", FocusWatcher._hook)
            FocusWatcher._hook := 0
        }
        if FocusWatcher._cb {
            CallbackFree(FocusWatcher._cb)
            FocusWatcher._cb := 0
        }
    }

    ; WinEventProc(hHook, event, hwnd, idObject, idChild, idThread, dwmsTime)
    static _Proc(hHook, event, hwnd, idObject, idChild, idThread, dwmsTime) {
        if (FocusWatcher._onChange != "")
            FocusWatcher._onChange.Call()
    }
}
