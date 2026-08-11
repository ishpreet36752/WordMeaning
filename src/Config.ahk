; Config.ahk — central configuration. All tunables live here; no magic numbers elsewhere.
#Requires AutoHotkey v2.0

class Config {
    ; --- App identity ---
    static AppName := "WordMeaning"
    static IconRelPath := "..\assets\wordmeaning.ico"   ; from src\ (dev run); ignored when compiled
    ; Per-user auto-start on login. HKCU only — no admin, no machine-wide change.
    static StartupRegKey := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"

    ; --- Bundled dictionary (the only source consulted by default) ---
    ; 86k entries generated from WordNet 3.1 by scripts\build-dictionary.ps1.
    ; Compiled builds carry it as a resource inside the .exe; a source run reads
    ; it from assets\. Either way no request leaves the machine for a lookup.
    static DictRelPath := "..\assets\dictionary.dat"    ; from src\ (dev run)
    static DictResourceName := "DICT"                   ; RT_RCDATA name when compiled

    ; --- Optional online fallback (off by default; user turns it on in the tray) ---
    ; WordNet is a fixed snapshot and misses newer or rarer words ("delimiter").
    ; Turning this on trades a network request for that coverage; leaving it off
    ; means the program never opens a socket at all.
    static OnlineFallbackDefault := false
    ; HTTPS only; hosts are pinned, word is path-encoded.
    static ApiBase := "https://freedictionaryapi.com/api/v1/entries/en/"
    ; The Wiktionary snapshot behind the primary has gaps of its own, so a miss
    ; there is not proof the word is undefined. One call, no key, definitions only.
    static ApiFallbackBase := "https://api.datamuse.com/words?md=d&max=1&sp="
    static OnlineMenuText := "Look up missing words online"

    ; Attribution for the bundled data and for the optional online sources
    ; (shown in tray → About). WordNet requires its notice be reproduced; the
    ; primary online source is CC BY-SA 4.0.
    static AttributionText := "Definitions from WordNet 3.1, Princeton University.`n"
                            . "WordNet 3.1 Copyright 2011 by Princeton University.`n"
                            . "All rights reserved. https://wordnet.princeton.edu/`n`n"
                            . "Optional online lookups (off by default):`n"
                            . "Wiktionary via FreeDictionaryAPI.com, CC BY-SA 4.0`n"
                            . "api.datamuse.com"

    ; --- Web-search fallback (user-initiated only — never opens the browser by itself) ---
    static WebSearchUrl := "https://www.google.com/search?q=define+"
    static WebSearchHotkey := "^+d"                     ; live only while a popup is showing
    static WebSearchHint := "Ctrl+Shift+D — search the web"

    ; --- Input validation ---
    ; Single English word: letters, internal apostrophe/hyphen. Hard length cap.
    static WordPattern := "^[A-Za-z][A-Za-z'\-]{0,31}$"
    static MaxWordLen := 32

    ; --- Selection detection ---
    static DragThresholdPx := 5        ; min mouse travel to count as drag-selection
    static DoubleClickMs := 400        ; max gap between clicks for double-click word-select

    ; --- Timing ---
    static ClipWaitSec := 0.3          ; how long to wait for Ctrl+C to fill clipboard
    static HttpTimeoutMs := 5000       ; resolve/connect/send/receive timeout
    static TooltipTimeoutMs := 6000    ; popup auto-hide
    static FocusPollMs := 250          ; active-window poll interval (window-switch dismiss)

    ; --- Behavior ---
    static MaxDefinitionLen := 300     ; truncate long definitions in popup
    static MaxExampleLen := 140        ; truncate the example sentence shown under it
    static PopupWrapWidth := 58        ; wrap popup text to this many chars/line (bounds width)
    static CacheMaxEntries := 200      ; in-memory lookup cache cap (per session, never persisted)
}
