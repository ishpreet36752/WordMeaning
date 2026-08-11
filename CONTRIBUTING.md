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
| `src/LocalDictionary.ahk` | Bundled dictionary: binary search over the packed data, inflection stripping |
| `src/Dictionary.ahk` | Validate, choose the sense, cache; optional online fallback |
| `src/Popup.ahk` | Tooltip show/hide |

## Running the tests

The dictionary is generated, not committed — build it once before running anything:

```powershell
.\scripts\build-dictionary.ps1        # writes assets\dictionary.dat
```

```powershell
$ahk = "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
& $ahk /ErrorStdOut tests\LoadTest.ahk     # expect: LOAD OK   (no network needed)
& $ahk /ErrorStdOut tests\DictTest.ahk     # expect: ALL PASS  (no network needed)
& $ahk /ErrorStdOut tests\WrapTest.ahk     # expect: ALL PASS  (no network needed)
& $ahk /ErrorStdOut tests\StartupTest.ahk  # expect: ALL PASS  (no network needed)
& $ahk /ErrorStdOut tests\SmokeTest.ahk    # expect: ALL PASS  (needs internet)
.\scripts\test-compiled.ps1                # expect: ALL PASS  (needs Ahk2Exe)
```

- **LoadTest** includes every module so all class initializers run — catches load-time faults.
- **DictTest** covers the bundled dictionary: search, inflections, sense choice, misses.
- **WrapTest** / **StartupTest** cover popup wrapping and the auto-start registry toggle.
- **SmokeTest** is the only test that uses a network: it covers the *optional* online fallback, which ships switched off.
- **test-compiled.ps1** compiles a probe and runs it, proving the .exe can read the dictionary embedded in it — the path every downloaded build uses, and the one no plain-script test can reach.

CI runs everything except `SmokeTest` on each push and pull request; the release workflow additionally runs the compiled check before building.

## Coding conventions

- **AutoHotkey v2 only** (`#Requires AutoHotkey v2.0` at the top of every file).
- Modules are `static` classes; keep state in class statics.
- Errors are returned as `{ ok: false, error: "..." }` result objects — do not throw across module boundaries.
- Put any new tunable in `Config.ahk`.

### AHK v2 gotchas (these bit us — please don't reintroduce)

- **Identifiers are case-insensitive.** A `static` field must never share a name with a method (e.g. `_onPress` vs `_OnPress()`), or the class fails to load with *"Property is read-only"*.
- **Prefer `.Bind(Class)` + `SetTimer`/`Hotkey` for callbacks** over `CallbackCreate`/`DllCall`, which hit `this`-binding ambiguity (*"Invalid callback function"*).

## Pull request checklist

- [ ] `LoadTest` prints `LOAD OK`; `DictTest`, `WrapTest`, `StartupTest` print `ALL PASS`.
- [ ] New tunables live in `Config.ahk`.
- [ ] Behavior invariants preserved (clipboard restored, single-word only, no pronunciation, offline by default, no disk persistence — see `CLAUDE.md`).
- [ ] No compiled or generated file added to the repository.
- [ ] Manually tested in at least a browser and a PDF reader.

## Scope

WordMeaning aims to stay **small and reliable**. Big features (offline dictionaries, OCR for scanned PDFs, multi-language, rich UI) are welcome as discussions first — open an issue before a large PR so we can agree on the approach.

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
