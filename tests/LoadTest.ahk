; LoadTest.ahk — includes every module so all class static-initializers run.
; Catches load-time faults (e.g. a static var colliding with a method name —
; AHK v2 identifiers are case-insensitive). Prints LOAD OK and exits 0 on success;
; on any init error, /ErrorStdOut emits the error and the script exits non-zero.
; Run: AutoHotkey64.exe /ErrorStdOut tests\LoadTest.ahk   (no network needed)
#Requires AutoHotkey v2.0
#Include ..\src\Config.ahk
#Include ..\src\Dictionary.ahk
#Include ..\src\Popup.ahk
#Include ..\src\SelectionWatcher.ahk
#Include ..\src\FocusWatcher.ahk

FileAppend("LOAD OK`n", "*")
ExitApp(0)
