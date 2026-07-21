; Config.ahk — central configuration. All tunables live here; no magic numbers elsewhere.
#Requires AutoHotkey v2.0

class Config {
    ; --- App identity ---
    static AppName := "WordMeaning"
    static IconRelPath := "..\assets\wordmeaning.ico"   ; from src\ (dev run); ignored when compiled
    ; Per-user auto-start on login. HKCU only — no admin, no machine-wide change.
    static StartupRegKey := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"

    ; --- Dictionary APIs (HTTPS only; hosts are pinned, word is path-encoded) ---
    ; Primary: Wiktionary data, no API key, structured senses with example sentences.
    static ApiBase := "https://freedictionaryapi.com/api/v1/entries/en/"
    ; Fallback: the primary's Wiktionary snapshot has gaps (e.g. "delimiter"), so a
    ; miss there is not proof the word is undefined. One call, no key, definitions only.
    static ApiFallbackBase := "https://api.datamuse.com/words?md=d&max=1&sp="
    ; Required attribution for the primary's CC BY-SA 4.0 text (shown in tray → About).
    static AttributionText := "Definitions from Wiktionary via FreeDictionaryAPI.com`n"
                            . "Text licensed CC BY-SA 4.0`n"
                            . "Fallback definitions from api.datamuse.com"

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
