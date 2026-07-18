; StartupTest.ahk — exercises the HKCU Run-key auto-start toggle end to end.
; Leaves the registry clean (disabled) afterward. No network.
; Run: AutoHotkey64.exe /ErrorStdOut tests\StartupTest.ahk
#Requires AutoHotkey v2.0
#Include ..\src\Config.ahk
#Include ..\src\Startup.ahk

fails := 0
Check(name, cond) {
    global fails
    FileAppend((cond ? "PASS " : "FAIL ") . name . "`n", "*")
    if !cond
        fails++
}

Startup.Disable()                                   ; clean slate
Check("starts disabled", !Startup.IsEnabled())
Startup.Enable()
Check("enable registers run key", Startup.IsEnabled())
Check("toggle off returns false", Startup.Toggle() == false)
Check("now disabled again", !Startup.IsEnabled())
Check("toggle on returns true", Startup.Toggle() == true)
Startup.Disable()                                   ; leave machine clean
Check("cleaned up", !Startup.IsEnabled())

FileAppend(fails == 0 ? "ALL PASS`n" : fails . " FAILURES`n", "*")
ExitApp(fails)
