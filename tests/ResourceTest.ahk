; ResourceTest.ahk — proves the compiled build can read its embedded dictionary.
;
; The uncompiled tests exercise the file-backed path; this one exercises the
; other half of LocalDictionary._Load: the RT_RCDATA resource inside the .exe.
; Nothing else covers it, and a failure there would ship a build that silently
; answers nothing until the user turns the network on.
;
; Compiled and run by scripts\test-compiled.ps1 — running it as a plain script
; is still useful (it then tests the file path) but proves less.
#Requires AutoHotkey v2.0
#Include ..\src\Config.ahk
#Include ..\src\LocalDictionary.ahk
#Include ..\src\Dictionary.ahk

;@Ahk2Exe-AddResource *10 ..\assets\dictionary.dat, DICT

; A compiled build has no console to write to, so results go to a file the
; caller reads; the exit code is the actual pass/fail signal.
logPath := A_Temp "\wordmeaning-resourcetest.txt"
try FileDelete(logPath)

fails := 0
Log(line) {
    global logPath
    FileAppend(line "`n", logPath, "UTF-8")
}
Check(name, cond) {
    global fails
    Log((cond ? "PASS " : "FAIL ") name)
    if !cond
        fails++
}

Log(A_IsCompiled ? "mode: compiled (resource)" : "mode: source (file)")

Check("dictionary available", LocalDictionary.Available())

r := Dictionary.Lookup("dog")
Check("known word resolves", r.ok && InStr(r.definition, "Canis"))
Check("part of speech carried", r.partOfSpeech == "noun")

r2 := Dictionary.Lookup("mice")
Check("irregular form resolves", r2.ok && r2.word == "mouse")

r3 := Dictionary.Lookup("qzxqzxqzx")
Check("unknown word missed cleanly", !r3.ok)

Check("no network needed", !Dictionary.onlineFallback)

Log(fails == 0 ? "ALL PASS" : fails " FAILURES")
ExitApp(fails)
