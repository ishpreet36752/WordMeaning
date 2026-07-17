# Contributing to WordMeaning

Thanks for your interest in improving WordMeaning! This is a small, focused tool — a system-wide word-definition popup for Windows. Contributions of all sizes are welcome.

## Ways to contribute

- **Report a bug** — open an issue with the *Bug report* template.
- **Suggest a feature** — open an issue with the *Feature request* template.
- **Improve docs** — README, this guide, code comments.
- **Send a pull request** — fix a bug or add a small, well-scoped feature.

## Development setup

1. Install [AutoHotkey v2](https://www.autohotkey.com/):
   ```powershell
   winget install AutoHotkey.AutoHotkey
   ```
2. Clone your fork and run the app:
   ```powershell
   .\run.ps1
   ```
   It appears in the system tray. Select a single word anywhere to see its meaning.

## Project layout

One responsibility per file (see `CLAUDE.md` for the full architecture):

| File | Responsibility |
|------|----------------|
| `src/Main.ahk` | Entry point, tray menu, wiring |
| `src/Config.ahk` | All tunables — never hardcode values elsewhere |
| `src/SelectionWatcher.ahk` | Detect selection, clipboard-safe capture, click-to-dismiss |
| `src/FocusWatcher.ahk` | Dismiss popup on window/app switch |
| `src/Dictionary.ahk` | API client: validate, fetch, parse, cache |
| `src/Popup.ahk` | Tooltip show/hide |

## Running the tests

```powershell
$ahk = "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
& $ahk /ErrorStdOut tests\LoadTest.ahk    # expect: LOAD OK   (no network needed)
& $ahk /ErrorStdOut tests\SmokeTest.ahk   # expect: ALL PASS  (needs internet)
```

- **LoadTest** includes every module so all class initializers run — catches load-time faults.
- **SmokeTest** exercises the dictionary lookup, validation, and cache.

CI runs `LoadTest` automatically on every push and pull request.

## Coding conventions

- **AutoHotkey v2 only** (`#Requires AutoHotkey v2.0` at the top of every file).
- Modules are `static` classes; keep state in class statics.
- Errors are returned as `{ ok: false, error: "..." }` result objects — do not throw across module boundaries.
- Put any new tunable in `Config.ahk`.

### AHK v2 gotchas (these bit us — please don't reintroduce)

- **Identifiers are case-insensitive.** A `static` field must never share a name with a method (e.g. `_onPress` vs `_OnPress()`), or the class fails to load with *"Property is read-only"*.
- **Prefer `.Bind(Class)` + `SetTimer`/`Hotkey` for callbacks** over `CallbackCreate`/`DllCall`, which hit `this`-binding ambiguity (*"Invalid callback function"*).

## Pull request checklist

- [ ] `LoadTest` prints `LOAD OK` and `SmokeTest` prints `ALL PASS`.
- [ ] New tunables live in `Config.ahk`.
- [ ] Behavior invariants preserved (clipboard restored, single-word only, no pronunciation, HTTPS only, no disk persistence — see `CLAUDE.md`).
- [ ] Manually tested in at least a browser and a PDF reader.

## Scope

WordMeaning aims to stay **small and reliable**. Big features (offline dictionaries, OCR for scanned PDFs, multi-language, rich UI) are welcome as discussions first — open an issue before a large PR so we can agree on the approach.

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
