; Config.ahk — central configuration. All tunables live here; no magic numbers elsewhere.
#Requires AutoHotkey v2.0

class Config {
    ; --- Dictionary API (HTTPS only; host is pinned, word is path-encoded) ---
    static ApiBase := "https://api.dictionaryapi.dev/api/v2/entries/en/"

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
    static PopupWrapWidth := 58        ; wrap popup text to this many chars/line (bounds width)
    static CacheMaxEntries := 200      ; in-memory lookup cache cap (per session, never persisted)
}
