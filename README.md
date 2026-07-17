# WordMeaning

> Select any word, anywhere on Windows, and its meaning pops up right next to your cursor.

[![CI](https://github.com/OWNER/WordMeaning/actions/workflows/ci.yml/badge.svg)](https://github.com/OWNER/WordMeaning/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![AutoHotkey v2](https://img.shields.io/badge/AutoHotkey-v2-334455.svg)](https://www.autohotkey.com/)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011-0078D6.svg)](#requirements)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

Reading an article, a PDF, or a document and hit a word you don't know? Instead of copying it and pasting into Google, just **double-click the word** — WordMeaning shows the definition in a small popup at your cursor. Works in your browser, PDF readers, Word, and almost any Windows app.

---

## Table of contents

- [Features](#features)
- [Demo](#demo)
- [Requirements](#requirements)
- [Install](#install)
- [Usage](#usage)
- [Start automatically with Windows](#start-automatically-with-windows)
- [Configuration](#configuration)
- [How it works](#how-it-works)
- [Privacy & security](#privacy--security)
- [Troubleshooting](#troubleshooting)
- [Limitations](#limitations)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Works everywhere** — any app where you can select text (drag or double-click).
- **Instant popup at the cursor** — word, part of speech, and definition. No pronunciation clutter.
- **Dismisses naturally** — click anywhere, switch windows (Alt+Tab), or wait 6 seconds.
- **Clipboard-safe** — whatever you had copied stays exactly as it was.
- **Private** — nothing is logged or saved to disk; lookups are cached in memory for the session only.
- **Lightweight** — a single AutoHotkey v2 script, lives in the system tray.
- **Free** — uses the free [dictionaryapi.dev](https://dictionaryapi.dev/) API, no account or API key.

## Demo

> _Add a short screen recording or GIF here (e.g. `docs/demo.gif`) once you have one._
>
> Double-click **serendipity** → a tooltip appears: _serendipity (noun) — the occurrence of events by chance in a happy or beneficial way._

## Requirements

- **Windows 10 or 11**
- **[AutoHotkey v2](https://www.autohotkey.com/)** (free)
- An **internet connection** (for the dictionary API)

## Install

1. **Install AutoHotkey v2:**
   ```powershell
   winget install AutoHotkey.AutoHotkey
   ```
   (Or download it from [autohotkey.com](https://www.autohotkey.com/) and choose the **v2** installer.)

2. **Get WordMeaning** — clone or download this repository:
   ```powershell
   git clone https://github.com/OWNER/WordMeaning.git
   cd WordMeaning
   ```
   (Or click **Code → Download ZIP** on GitHub and extract it.)

3. **Run it:**
   ```powershell
   .\run.ps1
   ```
   A tray icon appears near the clock. That's it — WordMeaning is now watching for word selections.

## Usage

1. **Double-click** any word — or drag-select it — in a browser, PDF, or document.
2. The definition appears in a popup **at your cursor**.
3. The popup goes away when you:
   - **click anywhere** (including on a different browser tab),
   - **switch to another window** (Alt+Tab or click another app), or
   - **wait 6 seconds**.

Selecting a **whole sentence or multiple words does nothing** — this is by design; WordMeaning looks up single words only.

### Tray menu

Right-click the tray icon:

- **Enabled** — toggle lookups on/off (handy when you're selecting a lot of text and don't want popups).
- **Exit** — quit WordMeaning.

## Start automatically with Windows

To have WordMeaning run every time you log in:

1. Press **Win + R**, type `shell:startup`, press Enter.
2. Create a shortcut in that folder pointing to `run.ps1` (or directly to `src\Main.ahk`).

## Configuration

All tunables live in [`src/Config.ahk`](src/Config.ahk). Common ones:

| Setting | Default | Meaning |
|---------|---------|---------|
| `TooltipTimeoutMs` | `6000` | How long the popup stays (milliseconds) |
| `MaxDefinitionLen` | `300` | Truncate long definitions to this many characters |
| `FocusPollMs` | `250` | How often to check for a window switch |
| `HttpTimeoutMs` | `5000` | Network timeout for the dictionary API |

Edit the file and restart WordMeaning to apply changes.

## How it works

WordMeaning is a small, modular AutoHotkey v2 app — one responsibility per file:

| File | Responsibility |
|------|----------------|
| `src/Main.ahk` | Entry point, tray menu, wiring |
| `src/Config.ahk` | All tunable values |
| `src/SelectionWatcher.ahk` | Detect a selection; copy it while preserving your clipboard; dismiss on click |
| `src/FocusWatcher.ahk` | Dismiss the popup when you switch windows |
| `src/Dictionary.ahk` | Validate the word, fetch over HTTPS, extract the definition, cache it |
| `src/Popup.ahk` | Show/hide the tooltip |

**Flow:** you select a word → it's captured via a clipboard-safe `Ctrl+C` probe → validated as a single word → looked up on dictionaryapi.dev → shown at your cursor.

## Privacy & security

- **No telemetry, no logging, no disk writes.** Looked-up words live only in an in-memory cache that is cleared when you quit.
- **Your clipboard is always restored** after each lookup, even if the lookup fails.
- **HTTPS only**, to a single pinned host. The selected word is URL-encoded and length-capped before any request.
- **Single-word only** — WordMeaning never sends sentences or arbitrary selected text anywhere.
- Only the word you select is sent to the dictionary API, and only to fetch its definition.

## Troubleshooting

**"AutoHotkey v2 not found" when running `run.ps1`**
Install it: `winget install AutoHotkey.AutoHotkey`. WordMeaning needs **v2**, not v1.

**A word gives "no definition found"**
The API is English-only and doesn't have every word (names, slang, very technical terms). Non-English words won't resolve.

**"offline / network error"**
Check your internet connection; the dictionary API needs to be reachable.

**Nothing happens when I select text in a PDF**
The PDF must have a real text layer. Scanned/image-only PDFs have no selectable text, so there's nothing to look up (that would need OCR — not supported).

**The popup lingers after I switch tabs with the keyboard**
Switching tabs with **Ctrl+Tab** (keyboard) stays in the same window, so it isn't detected as a window switch. Click the tab instead, or just wait for the 6-second timer. (Clicking anywhere dismisses the popup immediately.)

**An AutoHotkey error dialog appeared**
Please [open a bug report](https://github.com/OWNER/WordMeaning/issues/new?template=bug_report.yml) and paste the full error text.

## Limitations

- **English words only** (dictionaryapi.dev).
- **Single words only** — no phrases or idioms.
- **Scanned/image PDFs** aren't supported (no text to select).
- Password fields and other non-copyable UI text are silently skipped.

## Contributing

Contributions are very welcome! See **[CONTRIBUTING.md](CONTRIBUTING.md)** for setup, tests, and conventions, and please follow our **[Code of Conduct](CODE_OF_CONDUCT.md)**.

Good first contributions: docs, a demo GIF, extra troubleshooting entries, small quality-of-life options in `Config.ahk`.

## License

[MIT](LICENSE) — free to use, modify, and share.
