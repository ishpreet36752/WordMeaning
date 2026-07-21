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

; Regression: the primary source's first sense for "juxtaposition" is the obscure one
; ("the nearness of objects with little or no delimiter"), so the useful sense must
; come through as the alternative, with its example sentence.
r6 := Dictionary.Lookup("juxtaposition")
Check("second sense offered", r6.ok && r6.altDefinition != "")
Check("example sentence carried", r6.ok && InStr(r6.example, "juxtaposition"))

; Regression: absent from the old dictionaryapi.dev snapshot — must resolve now.
r7 := Dictionary.Lookup("delimiter")
Check("stale-snapshot word resolves", r7.ok && r7.definition != "")

; Regression: "cat" is filed under a Wiktionary grouping heading, not a definition.
r8 := Dictionary.Lookup("cat")
Check("grouping heading skipped", r8.ok && !InStr(r8.definition, "Terms relating to"))
Check("grammatical tag stripped", r8.ok && !InStr(r8.definition, "(countable)"))

; Citations must never reach the popup — an example is a plain usage sentence or nothing.
r9 := Dictionary.Lookup("ephemeral")
Check("citation rejected as example", r9.ok && !RegExMatch(r9.example, "^\d{4}"))

FileAppend(fails == 0 ? "ALL PASS`n" : fails . " FAILURES`n", "*")
ExitApp(fails)
