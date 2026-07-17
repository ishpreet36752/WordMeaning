# WordMeaning

Select a word anywhere on your Windows PC — browser, PDF reader, Word, any app — and its meaning pops up next to your cursor. No copy-paste, no switching to Google.

## Features

- **Works everywhere**: any app where text can be selected (drag or double-click).
- **Instant popup** at the cursor: word, part of speech, definition. No pronunciation clutter.
- **Clipboard-safe**: whatever you had copied stays intact.
- **Private**: nothing is logged or saved to disk; lookups are cached in memory for the session only.
- **Tray control**: toggle on/off or exit from the system tray icon.

## Requirements

- Windows 10/11
- [AutoHotkey v2](https://www.autohotkey.com/) (`winget install AutoHotkey.AutoHotkey`)
- Internet connection (uses the free [dictionaryapi.dev](https://dictionaryapi.dev/) API — no key needed)

## Run

```powershell
.\run.ps1
```

Or double-click `src\Main.ahk` after installing AutoHotkey v2.

### Start with Windows (optional)

Create a shortcut to `src\Main.ahk` in `shell:startup` (Win+R → `shell:startup`).

## Usage

1. Double-click a word, or drag-select it.
2. Definition appears at your cursor for ~4 seconds.
3. Selecting a sentence or multiple words does nothing (by design — words only).

## Limitations

- English words only (dictionaryapi.dev).
- Scanned/image-only PDFs have no selectable text — no lookup possible (would need OCR).
- Password fields and non-copyable UI text are silently skipped.

## Configuration

All tunables (popup duration, timeouts, word length cap, etc.) are in `src/Config.ahk`.
