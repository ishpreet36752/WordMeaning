# WordMeaning

System-wide word-definition popup for Windows. Select a single word in any app (browser, PDF reader, Word) → definition tooltip appears at the cursor. Built with AutoHotkey v2.

## Run

```powershell
.\run.ps1
```

(`run.ps1` finds AutoHotkey v2 in user-scope `%LOCALAPPDATA%\Programs\AutoHotkey` or machine-scope `Program Files`.) Runs in the system tray. Tray menu: Enabled (toggle), Start with Windows (toggle), Exit.

## Build a standalone .exe

```powershell
.\build.ps1
```

Produces `dist/WordMeaning.exe` (single file, all modules bundled, tray icon embedded). Runs on any Windows PC with **no AutoHotkey install and no source files present** — copy it anywhere as a portable backup. Needs the Ahk2Exe compiler at `%LOCALAPPDATA%\Programs\AutoHotkey\Compiler\Ahk2Exe.exe` (install via `UX\install-ahk2exe.ahk` or unzip a release from github.com/AutoHotkey/Ahk2Exe).

If [Inno Setup](https://jrsoftware.org/isdl.php) is installed (`%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe`), `build.ps1` also compiles `installer/WordMeaning.iss` into `dist/WordMeaning-Setup.exe` — a per-user installer (no admin) with Start-menu + optional desktop shortcut, an optional "Start with Windows" checkbox (writes the same HKCU Run key as the tray toggle), and a clean uninstaller. `dist/` is git-ignored — it is a build artifact, regenerate with `build.ps1`.

## Website / distribution

The download site is `docs/index.html`, published by GitHub Pages from `main` + `/docs` at
**https://ishpreet36752.github.io/WordMeaning/**. There is no GitHub Release; the site *is* the
distribution channel.

Pages can only serve files committed to the repo, so `docs/downloads/` holds committed copies of
both binaries (this is why those binaries are in git while `dist/` is ignored). `build.ps1` refreshes
those copies automatically as its last step — **commit and push `docs/downloads/` or the site keeps
serving the previous build.**

The landing page is a single self-contained file: inline CSS/SVG/JS, no external requests, no
webfonts, no analytics. Its hero demo is driven by real `window.getSelection()` and deliberately
mirrors the app's behavior — `Config.WordPattern` verbatim, the 6s `TooltipTimeoutMs` auto-hide,
mousedown-hides/mouseup-resolves ordering, and total silence on a multi-word selection (because
`Main.ahk` suppresses the `"not a single word"` error). **If you change those behaviors in `src/`,
update the demo too** or the page starts teaching a gesture the program doesn't have.

The tray/app icon is `assets/wordmeaning.ico` (committed source asset; regenerate with `scripts/make-icon.ps1` if present). `build.ps1` embeds it via Ahk2Exe `/icon`; the uncompiled dev run loads it via `TraySetIcon` (`Main.SetTrayIcon`, guarded by `A_IsCompiled`).

## Architecture (modular — one responsibility per file)

- `src/Main.ahk` — entry point, wiring, tray menu, enable/disable state. Includes the other modules.
- `src/Config.ahk` — ALL tunables (timeouts, regex, API base, caps). Never hardcode values elsewhere.
- `src/SelectionWatcher.ahk` — global mouse hook. Detects drag-select or double-click, captures selection via clipboard-preserving Ctrl+C probe. Also fires an onPress callback so any click dismisses a stale popup.
- `src/FocusWatcher.ahk` — polls the active window id on a timer; fires onChange when the foreground window changes (Alt+Tab, app switch) so the popup is dismissed.
- `src/Dictionary.ahk` — dictionaryapi.dev client. Input validation, HTTPS fetch, minimal JSON field extraction, session cache.
- `src/Popup.ahk` — tooltip display/hide.
- `src/Startup.ahk` — optional "run at login" toggle via the per-user `HKCU\...\Run` key. HKCU only (no admin, no machine-wide change); stores only the launch command, never any looked-up data.

Flow: SelectionWatcher → Main.OnSelection (word filter) → Dictionary.Lookup → Popup.Show.
Dismiss: SelectionWatcher.onPress (click) and FocusWatcher.onChange (window switch) → Popup.Hide; plus the 6s auto-hide timer.

### AHK v2 gotcha (caused two load crashes — do not repeat)

Identifiers are **case-insensitive**. A `static` field must never share a name with a method (e.g. `_onPress` vs `_OnPress()`), or init fails with "Property is read-only". For OS/timer callbacks prefer a `.Bind(Class)` method + `SetTimer` (proven here) over `CallbackCreate`/`DllCall`, which hit `this`-binding ambiguity ("Invalid callback function").

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

Automated:
- `tests/LoadTest.ahk` — includes every module so all class static-initializers run; catches load-time faults like the case-insensitive name collision above. No network needed.
- `tests/SmokeTest.ahk` — Dictionary validation/fetch/parse/cache (needs internet).
- `tests/WrapTest.ahk` — deterministic Popup word-wrapping checks. No network.
- `tests/StartupTest.ahk` — exercises the HKCU Run-key auto-start toggle end to end; leaves the registry clean afterward. No network.

```powershell
$ahk = "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
& $ahk /ErrorStdOut tests\LoadTest.ahk     # expect: LOAD OK
& $ahk /ErrorStdOut tests\SmokeTest.ahk    # expect: ALL PASS
& $ahk /ErrorStdOut tests\WrapTest.ahk     # expect: ALL PASS
& $ahk /ErrorStdOut tests\StartupTest.ahk  # expect: ALL PASS
```

Note: `LoadTest` only runs static initializers, not `Start()` methods. To catch errors inside a watcher's `Start()` (e.g. bad callback setup), run `src/Main.ahk` with stderr captured — clean means the process stays alive AND stderr is empty (a lingering error dialog is itself an `AutoHotkey64.exe` process, so a bare pid check is not proof of a clean load).

Hook/UI code has no automated coverage. Manual test matrix after any change:
1. Chrome webpage — double-click a word → popup shows meaning, no pronunciation.
2. PDF with text layer (Edge or Adobe) — drag-select a word → popup.
3. Word/Notepad — both select methods.
4. Copy something first, do a lookup, paste — original clipboard must be intact.
5. Select a full sentence — no popup, no error.
6. Disconnect network, select a word — "offline / network error" popup, no crash.
