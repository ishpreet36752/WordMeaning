; DictTest.ahk — the bundled offline dictionary: binary search, inflection
; handling, sense selection, and the guarantee that a lookup needs no network.
; Run: AutoHotkey64.exe /ErrorStdOut tests\DictTest.ahk   (no network needed)
;
; Requires assets\dictionary.dat — build it with scripts\build-dictionary.ps1.
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

; The rest of the suite is meaningless without the data, so fail loudly here
; rather than reporting a string of confusing misses.
if !LocalDictionary.Available() {
    FileAppend("FAIL dictionary not loaded - run scripts\build-dictionary.ps1`n", "*")
    FileAppend("1 FAILURES`n", "*")
    ExitApp(1)
}
Check("dictionary loads", LocalDictionary.Available())

; --- Binary search finds entries across the whole file ----------------------
; Deliberately spread across the alphabet: a search that only works near the
; middle of the file would still pass a single-word test.
for w in ["aardvark", "cat", "dog", "ephemeral", "juxtaposition", "meaning"
        , "serendipity", "obfuscate", "quixotic", "zygote"] {
    r := Dictionary.Lookup(w)
    Check("finds '" . w . "'", r.ok && r.definition != "")
}

; First and last records specifically: an off-by-one in the search bounds shows
; up at the ends, not in the middle.
rFirst := Dictionary.Lookup("a")
Check("finds the first entry", rFirst.ok && rFirst.definition != "")
; "zyrian" is the very last record in the file — the case where the search runs
; out of bytes rather than finding a larger key to stop at.
rLast := Dictionary.Lookup("zyrian")
Check("finds the last entry", rLast.ok && rLast.definition != "")

; --- Records are well formed ------------------------------------------------
r := Dictionary.Lookup("dog")
Check("part of speech carried", r.partOfSpeech == "noun")
Check("example carried", InStr(r.example, "dog"))
Check("definition is not the header line", SubStr(r.definition, 1, 1) != "#")

r := Dictionary.Lookup("cat")
Check("second sense offered where one exists", r.ok && r.altDefinition != "")

; --- Frequency picks the reading a reader actually hit ----------------------
; "better" has more verb senses than adjective ones, but the tagged corpora say
; the adjective outweighs the verb 92 to 3.
rBetter := Dictionary.Lookup("better")
Check("frequency chooses the part of speech", rBetter.partOfSpeech == "adjective")

; --- Inflections ------------------------------------------------------------
; Irregular forms ship as redirect records; regular ones are stripped by rule.
rRan := Dictionary.Lookup("ran")
Check("irregular verb resolves", rRan.ok && rRan.word == "run")
rMice := Dictionary.Lookup("mice")
Check("irregular plural resolves", rMice.ok && rMice.word == "mouse")
rDogs := Dictionary.Lookup("dogs")
Check("regular plural resolves", rDogs.ok && rDogs.word == "dog")
rPonies := Dictionary.Lookup("ponies")
Check("-ies plural resolves", rPonies.ok && rPonies.word == "pony")
rWalked := Dictionary.Lookup("walked")
Check("past tense resolves", rWalked.ok && rWalked.word == "walk")
rRunning := Dictionary.Lookup("running")
Check("-ing form resolves", rRunning.ok)

; A word that is itself a headword must not be mangled into another one:
; "as" must not become "a", "bus" must not become "bu".
rAs := Dictionary.Lookup("as")
Check("headword wins over suffix stripping", rAs.ok && rAs.word == "as")

; A word WordNet has no entry for can still be answered through its root. The
; popup header shows the word that was resolved to, so nothing is misattributed:
; selecting "delimiter" reads "delimit (verb)".
rDelim := Dictionary.Lookup("delimiter")
Check("word resolves through its root", rDelim.ok && rDelim.word == "delimit")

; --- Misses -----------------------------------------------------------------
; Offline-only is the default, so an unknown word must fail without a request.
Check("online fallback is off by default", !Dictionary.onlineFallback)
rMiss := Dictionary.Lookup("qzxqzxqzx")
Check("unknown word missed cleanly", !rMiss.ok && rMiss.error == "no definition found")

; --- Validation still gates the lookup --------------------------------------
rMulti := Dictionary.Lookup("two words")
Check("multi-word rejected", !rMulti.ok && rMulti.error == "not a single word")
rJunk := Dictionary.Lookup("a1b2!")
Check("non-word rejected", !rJunk.ok && rJunk.error == "not a single word")

; --- Cache ------------------------------------------------------------------
rCache := Dictionary.Lookup("dog")
Check("cache hit consistent", rCache.definition == Dictionary.Lookup("dog").definition)

FileAppend(fails == 0 ? "ALL PASS`n" : fails . " FAILURES`n", "*")
ExitApp(fails)
