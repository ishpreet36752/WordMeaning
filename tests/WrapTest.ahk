; WrapTest.ahk — deterministic checks for Popup word-wrapping. No network.
; Run: AutoHotkey64.exe /ErrorStdOut tests\WrapTest.ahk
#Requires AutoHotkey v2.0
#Include ..\src\Config.ahk
#Include ..\src\Popup.ahk

fails := 0
Check(name, cond) {
    global fails
    FileAppend((cond ? "PASS " : "FAIL ") . name . "`n", "*")
    if !cond
        fails++
}

; No line in the wrapped output exceeds the width.
LongestLine(s) {
    max := 0
    for line in StrSplit(s, "`n")
        if (StrLen(line) > max)
            max := StrLen(line)
    return max
}

long := "A necessity or prerequisite; something required or obligatory in relation to what is required."
w := Popup._Wrap(long, 58)
Check("wraps under width", LongestLine(w) <= 58)
Check("wrapping added line breaks", InStr(w, "`n"))
Check("no words lost", StrReplace(w, "`n", " ") == long)

short := "serendipity (noun)"
Check("short text unchanged", Popup._Wrap(short, 58) == short)

; Existing newlines (header vs definition) are preserved.
two := "word (noun)`nsome definition here"
Check("keeps explicit newlines", InStr(Popup._Wrap(two, 58), "word (noun)`n"))

FileAppend(fails == 0 ? "ALL PASS`n" : fails . " FAILURES`n", "*")
ExitApp(fails)
