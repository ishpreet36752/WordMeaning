# WordMeaning

System-wide word-definition popup for Windows. Select a single word in any app (browser, PDF reader, Word) → definition tooltip appears at the cursor. Built with AutoHotkey v2.

## Run

```powershell
.\run.ps1
```

(`run.ps1` finds AutoHotkey v2 in user-scope `%LOCALAPPDATA%\Programs\AutoHotkey` or machine-scope `Program Files`.) Runs in the system tray. Tray menu: Enabled (toggle), Exit.

## Architecture (modular — one responsibility per file)

- `src/Main.ahk` — entry point, wiring, tray menu, enable/disable state. Includes the other modules.
- `src/Config.ahk` — ALL tunables (timeouts, regex, API base, caps). Never hardcode values elsewhere.
- `src/SelectionWatcher.ahk` — global mouse hook. Detects drag-select or double-click, captures selection via clipboard-preserving Ctrl+C probe.
- `src/Dictionary.ahk` — dictionaryapi.dev client. Input validation, HTTPS fetch, minimal JSON field extraction, session cache.
- `src/Popup.ahk` — tooltip display/hide.

Flow: SelectionWatcher → Main.OnSelection (word filter) → Dictionary.Lookup → Popup.Show.

## Invariants (do not break)

- **Clipboard is always restored** after the Ctrl+C probe, even on failure (`SelectionWatcher._CaptureSelection`).
- **Single-word only**: `Config.WordPattern` gates both the watcher callback and `Dictionary.Lookup`. Multi-word selections are silently ignored.
- **No pronunciation**: phonetic/audio fields from the API are deliberately never parsed or shown.
- **HTTPS only**, host pinned in `Config.ApiBase`; the word is URL-path-encoded and length-capped (`MaxWordLen`) before any request.
- **No persistence**: looked-up words live only in the in-memory session cache (`CacheMaxEntries` cap). Nothing is written to disk or logged.
- **Deterministic behavior**: same word → same cached result within a session; all timing values come from `Config`.

## Conventions

- AutoHotkey v2 syntax only (`#Requires AutoHotkey v2.0` in every file).
- Static classes as modules; state kept in class statics, except `enabled` (Main-level global).
- Errors surface as `{ ok: false, error: "…" }` result objects, never thrown across module boundaries.

## Testing

Automated: `tests/SmokeTest.ahk` covers Dictionary validation/fetch/parse/cache (needs internet):

```powershell
& "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe" /ErrorStdOut tests\SmokeTest.ahk
```

Hook/UI code has no automated coverage. Manual test matrix after any change:
1. Chrome webpage — double-click a word → popup shows meaning, no pronunciation.
2. PDF with text layer (Edge or Adobe) — drag-select a word → popup.
3. Word/Notepad — both select methods.
4. Copy something first, do a lookup, paste — original clipboard must be intact.
5. Select a full sentence — no popup, no error.
6. Disconnect network, select a word — "offline / network error" popup, no crash.
