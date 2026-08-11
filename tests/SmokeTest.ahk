; SmokeTest.ahk — the optional online fallback: the HTTPS clients and their
; parsers. Everything the bundled dictionary answers is covered by DictTest,
; which needs no network; this file covers only the path the user has to switch
; on, and it is the only test that touches the internet.
; Run: AutoHotkey64.exe /ErrorStdOut tests\SmokeTest.ahk   (needs internet)
#Requires AutoHotkey v2.0
#Include ..\src\Config.ahk
#Include ..\src\LocalDictionary.ahk
#Include ..\src\Dictionary.ahk

fails := 0

Check(name, cond) {
    global fails
    FileAppend((cond ? "PASS " : "FAIL ") . name . "`n", "*")
    if !cond
        fails++
}

; --- Offline-only is the default and it must not reach the network ----------
Check("online fallback off by default", !Dictionary.onlineFallback)
rOff := Dictionary.Lookup("qzxqzxqzx")
Check("unknown word fails without the network", !rOff.ok && rOff.error == "no definition found")

Dictionary.onlineFallback := true
Dictionary.ClearCache()

; --- End to end: a word WordNet does not carry ------------------------------
; WordNet 3.1 predates it and no suffix rule reaches a root that is in there, so
; this only passes if the fallback actually fired and parsed a response. It is
; also the reason the fallback exists: a fixed corpus ages.
r := Dictionary.Lookup("selfie")
Check("word missing offline resolves online", r.ok && r.definition != "")

r2 := Dictionary.Lookup("qzxqzxqzx")
Check("unknown word rejected", !r2.ok && r2.error == "no definition found")

r3 := Dictionary.Lookup("two words")
Check("multi-word rejected", !r3.ok && r3.error == "not a single word")

; --- The API parsers, exercised directly ------------------------------------
; Lookup() would answer these from the bundled dictionary and never call out, so
; the regressions below go through _Fetch, which is the network client itself.

; The primary source orders senses historically, so the useful reading of
; "juxtaposition" is not the first one and must come through as the alternative.
f1 := Dictionary._Fetch("juxtaposition")
Check("second sense offered", f1.ok && f1.altDefinition != "")
Check("example sentence carried", f1.ok && InStr(f1.example, "juxtaposition"))

; "cat" is filed under a Wiktionary grouping heading, not a definition.
f2 := Dictionary._Fetch("cat")
Check("grouping heading skipped", f2.ok && !InStr(f2.definition, "Terms relating to"))
Check("grammatical tag stripped", f2.ok && !InStr(f2.definition, "(countable)"))

; Citations must never reach the popup — an example is a plain usage sentence
; or nothing at all.
f3 := Dictionary._Fetch("ephemeral")
Check("citation rejected as example", f3.ok && !RegExMatch(f3.example, "^\d{4}"))

; --- Toggling back off must not keep serving cached online answers ----------
Dictionary.onlineFallback := false
Dictionary.ClearCache()
rBack := Dictionary.Lookup("selfie")
Check("switching off stops using the network", !rBack.ok)

FileAppend(fails == 0 ? "ALL PASS`n" : fails . " FAILURES`n", "*")
ExitApp(fails)
