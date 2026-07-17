; SmokeTest.ahk — deterministic checks for Dictionary validation/fetch/parse.
; Run: AutoHotkey64.exe /ErrorStdOut tests\SmokeTest.ahk   (needs internet for case 1-2)
#Requires AutoHotkey v2.0
#Include ..\src\Config.ahk
#Include ..\src\Dictionary.ahk

fails := 0

Check(name, cond) {
    global fails
    FileAppend((cond ? "PASS " : "FAIL ") . name . "`n", "*")
    if !cond
        fails++
}

r := Dictionary.Lookup("serendipity")
Check("known word ok", r.ok && r.definition != "")

r2 := Dictionary.Lookup("qzxqzxqzx")
Check("unknown word rejected", !r2.ok && r2.error == "no definition found")

r3 := Dictionary.Lookup("two words")
Check("multi-word rejected", !r3.ok && r3.error == "not a single word")

r4 := Dictionary.Lookup("a1b2!")
Check("non-word rejected", !r4.ok && r4.error == "not a single word")

r5 := Dictionary.Lookup("serendipity")
Check("cache hit consistent", r5.ok && r5.definition == r.definition)

FileAppend(fails == 0 ? "ALL PASS`n" : fails . " FAILURES`n", "*")
ExitApp(fails)
