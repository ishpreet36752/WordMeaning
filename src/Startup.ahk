; Startup.ahk — optional "run at login" via the per-user HKCU Run key.
; HKCU only: no admin rights, no machine-wide change, nothing outside this user's hive.
; Stores just the launch command (a path), never any looked-up data.
#Requires AutoHotkey v2.0

class Startup {
    ; The exact command Windows runs at login to relaunch this app.
    ; Compiled: the .exe itself. Dev run: the AHK interpreter + this script.
    static _Command() {
        if A_IsCompiled
            return '"' A_ScriptFullPath '"'
        return '"' A_AhkPath '" "' A_ScriptFullPath '"'
    }

    static IsEnabled() {
        try
            return RegRead(Config.StartupRegKey, Config.AppName) != ""
        catch
            return false        ; value absent -> not registered
    }

    static Enable() {
        RegWrite(Startup._Command(), "REG_SZ", Config.StartupRegKey, Config.AppName)
    }

    static Disable() {
        try RegDelete(Config.StartupRegKey, Config.AppName)
    }

    ; Flip state; return the new enabled state.
    static Toggle() {
        Startup.IsEnabled() ? Startup.Disable() : Startup.Enable()
        return Startup.IsEnabled()
    }
}
