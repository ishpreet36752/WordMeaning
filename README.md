# WordMeaning

> Select any word, anywhere on Windows, and its meaning pops up right next to your cursor.

[![CI](https://github.com/ishpreet36752/WordMeaning/actions/workflows/ci.yml/badge.svg)](https://github.com/ishpreet36752/WordMeaning/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![AutoHotkey v2](https://img.shields.io/badge/AutoHotkey-v2-334455.svg)](https://www.autohotkey.com/)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011-0078D6.svg)](#requirements)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

Reading an article, a PDF, or a document and hit a word you don't know? Instead of copying it and pasting into Google, just **double-click the word** — WordMeaning shows the definition in a small popup at your cursor. Works in your browser, PDF readers, Word, and almost any Windows app.

## Demo

<video src="https://github.com/user-attachments/assets/23baf418-fee1-4151-8b93-dbb418632a53" controls muted loop width="520"></video>

20 seconds: select a word, the meaning appears at the cursor. Prefer it in a tab? ▶ **[Open the video](https://ishpreet36752.github.io/WordMeaning/assets/demo.mp4)** — or try the real interaction in your browser at [ishpreet36752.github.io/WordMeaning](https://ishpreet36752.github.io/WordMeaning/).

---

## Table of contents

- [Features](#features)
- [Download & install](#download--install)
- [Run from source (developers)](#run-from-source-developers)
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
- **Instant popup at the cursor** — word, part of speech, up to two meanings, and an example sentence when there is one. No pronunciation clutter.
- **Readable meanings** — the dictionary's first sense is often the archaic one, so the popup also shows the most useful sense it can find.
- **Web fallback** — if no dictionary has the word, press **Ctrl+Shift+D** while the popup is up to search for it in your browser. The program never opens the browser on its own.
- **Dismisses naturally** — click anywhere, switch windows (Alt+Tab), or wait 6 seconds.
- **Clipboard-safe** — whatever you had copied stays exactly as it was.
- **Private** — nothing is logged or saved to disk; lookups are cached in memory for the session only.
- **Lightweight** — a single AutoHotkey v2 script, lives in the system tray.
- **Works offline** — the dictionary ships inside the program (86,000 entries from [WordNet](https://wordnet.princeton.edu/)). No request leaves your machine for a lookup, and nothing breaks on a plane.
- **Free** — no account, no API key, no server to depend on.

## Download & install

### → [ishpreet36752.github.io/WordMeaning](https://ishpreet36752.github.io/WordMeaning/)

Both downloads live on the site, and you can try the actual interaction there before installing anything.

**Requirements:** Windows 10 or 11. **No internet connection** — the dictionary is bundled. **No AutoHotkey install needed** — everything is in the download.

| | |
|---|---|
| **[Installer](https://github.com/ishpreet36752/WordMeaning/releases/latest/download/WordMeaning-Setup.exe)** (recommended) | Guided setup. Start-menu shortcut, optional desktop icon, optional *Start with Windows*, and a clean uninstall from *Add or remove programs*. Per-user: **no administrator rights**. |
| **[Portable](https://github.com/ishpreet36752/WordMeaning/releases/latest/download/WordMeaning.exe)** | One self-contained file — program and dictionary in a single .exe. Double-click to run; copy it to a USB stick or another PC. Nothing is written outside the app unless you turn on *Start with Windows* from the tray menu. |

Either way, a tray icon (a blue **W**) appears near the clock and WordMeaning starts watching for word selections.

> **Windows will warn you on first launch.** SmartScreen shows an "unrecognised app" dialog for any program whose publisher hasn't paid for a code-signing certificate, and this one hasn't. Click **More info**, then **Run anyway**. If you'd rather check first, the whole program is about eight hundred lines of AutoHotkey in [`src/`](src/).

### Verify what you downloaded

You should not have to take anyone's word that a binary matches the source it claims to come from. Both files are built by [GitHub Actions](.github/workflows/release.yml) on a clean runner from the tagged commit, with a signed build provenance attestation. Check yours with the [GitHub CLI](https://cli.github.com/):

```powershell
gh attestation verify WordMeaning.exe --repo ishpreet36752/WordMeaning
```

That fails unless the exact bytes you have came out of that workflow, from this repository. Every release also carries a `SHA256SUMS.txt`.

Nothing compiled is committed to this repository — the binaries exist only as release artifacts, and the bundled dictionary is [generated](scripts/build-dictionary.ps1) from a checksum-pinned WordNet release rather than checked in.

## Run from source (developers)

Prefer to run the raw script or hack on it?

1. **Install AutoHotkey v2:**
   ```powershell
   winget install AutoHotkey.AutoHotkey
   ```
   (Or download the **v2** installer from [autohotkey.com](https://www.autohotkey.com/).)

2. **Get the code:**
   ```powershell
   git clone https://github.com/ishpreet36752/WordMeaning.git
   cd WordMeaning
   ```

3. **Build the dictionary** (once — it is generated, not committed):
   ```powershell
   .\scripts\build-dictionary.ps1
   ```
   Downloads the pinned WordNet 3.1 release, verifies its checksum, and writes `assets\dictionary.dat` (~7.5 MB, about a minute).

4. **Run it:**
   ```powershell
   .\run.ps1
   ```

5. **Build your own `.exe` / installer** (optional):
   ```powershell
   .\build.ps1
   ```
   Produces `dist\WordMeaning.exe`, plus `dist\WordMeaning-Setup.exe` if [Inno Setup](https://jrsoftware.org/isdl.php) is installed. Releases are built by CI from a tag, not uploaded by hand.

## Usage

1. **Double-click** any word — or drag-select it — in a browser, PDF, or document.
2. The definition appears in a popup **at your cursor**.
3. The popup goes away when you:
   - **click anywhere** (including on a different browser tab),
   - **switch to another window** (Alt+Tab or click another app), or
   - **wait 6 seconds**.
4. If the word isn't in the dictionaries, the popup says so and offers **Ctrl+Shift+D** — press it while the popup is up to search the web for that word. That shortcut only exists while a popup is showing, so it never shadows the same keys in other programs.

Selecting a **whole sentence or multiple words does nothing** — this is by design; WordMeaning looks up single words only.

### Tray menu

Right-click the tray icon (the blue **W**):

- **Enabled** — toggle lookups on/off (handy when you're selecting a lot of text and don't want popups).
- **Start with Windows** — toggle launching WordMeaning automatically at login. A checkmark shows it's on. Flip it anytime.
- **Exit** — quit WordMeaning.

## Start automatically with Windows

Easiest: right-click the tray icon and tick **Start with Windows** (or tick the box in the installer). This registers a per-user login entry — no admin, and you can turn it off from the same menu.

Running from source instead? The tray toggle still works. As a manual alternative you can press **Win + R**, type `shell:startup`, and drop a shortcut to `run.ps1` in that folder. (Don't copy `src\Main.ahk` there on its own — it needs the other files next to it.)

## Configuration

All tunables live in [`src/Config.ahk`](src/Config.ahk). Common ones:

| Setting | Default | Meaning |
|---------|---------|---------|
| `TooltipTimeoutMs` | `6000` | How long the popup stays (milliseconds) |
| `MaxDefinitionLen` | `300` | Truncate long definitions to this many characters |
| `FocusPollMs` | `250` | How often to check for a window switch |
| `OnlineFallbackDefault` | `false` | Whether the optional online lookup starts switched on |
| `HttpTimeoutMs` | `5000` | Network timeout, used only by that optional fallback |
| `MaxExampleLen` | `140` | Longest example sentence shown (longer ones are dropped) |
| `WebSearchUrl` | Google `define+` | Where Ctrl+Shift+D sends the word (e.g. swap in Wiktionary) |
| `WebSearchHotkey` | `^+d` | The web-search shortcut, live only while a popup is showing |

Edit the file and restart WordMeaning to apply changes.

## How it works

WordMeaning is a small, modular AutoHotkey v2 app — one responsibility per file:

| File | Responsibility |
|------|----------------|
| `src/Main.ahk` | Entry point, tray menu, wiring |
| `src/Config.ahk` | All tunable values |
| `src/SelectionWatcher.ahk` | Detect a selection; copy it while preserving your clipboard; dismiss on click |
| `src/FocusWatcher.ahk` | Dismiss the popup when you switch windows |
| `src/LocalDictionary.ahk` | The bundled dictionary: binary-search the packed data, strip regular inflections |
| `src/Dictionary.ahk` | Validate the word, pick the sense to show, cache it; optional online fallback |
| `src/Popup.ahk` | Show/hide the tooltip |
| `src/Startup.ahk` | Optional "run at login" toggle (per-user registry key; no admin) |

**Flow:** you select a word → it's captured via a clipboard-safe `Ctrl+C` probe → validated as a single word → looked up in the bundled dictionary → the most useful sense is picked → shown at your cursor.

The dictionary is ~86,000 entries packed into one sorted, tab-separated file, generated from WordNet 3.1 by [`scripts/build-dictionary.ps1`](scripts/build-dictionary.ps1). It travels as a resource inside the .exe, and a lookup binary-searches those bytes in place rather than loading them into a map — so a lookup costs a few memory reads, and the portable build stays a single file that writes nothing to disk.

Words the bundled data has no entry for are resolved through their root where possible (`delimiter` → `delimit`), and the popup shows the word it actually resolved to. If you want coverage beyond a fixed corpus — new slang, very recent terms — tray → **Look up missing words online** enables an HTTPS fallback for misses only. It is **off by default** and not remembered between runs.

## Privacy & security

- **No network by default.** Lookups are answered from data inside the program. Nothing is sent anywhere unless you switch the online fallback on yourself.
- **No telemetry, no logging, no disk writes.** Looked-up words live only in an in-memory cache that is cleared when you quit.
- **Your clipboard is always restored** after each lookup, even if the lookup fails.
- **Single-word only** — WordMeaning never sends sentences or arbitrary selected text anywhere.
- If you do enable the online fallback: **HTTPS only**, to two pinned hosts, one word at a time, URL-encoded and length-capped. Nothing else is included in the request.
- **Your browser is only opened by you.** Ctrl+Shift+D works only while a popup is showing, and only then does the word reach a search engine (and your browser history).

## Troubleshooting

**"AutoHotkey v2 not found" when running `run.ps1`**
Install it: `winget install AutoHotkey.AutoHotkey`. WordMeaning needs **v2**, not v1.

**A word gives "no definition found"**
The bundled dictionary is English-only and, being a fixed corpus, has no names, brand names, or very new slang. Press **Ctrl+Shift+D** while the popup is up to search the web for that word instead, or turn on tray → **Look up missing words online** to have misses checked against an online dictionary.

**"offline / network error"**
Only possible with the online fallback switched on — check your connection, or switch it back off and rely on the bundled dictionary.

**"dictionary unavailable"**
The bundled data could not be read. In a source checkout, generate it: `.\scripts\build-dictionary.ps1`. In a downloaded build this should never happen — please [open a bug report](https://github.com/ishpreet36752/WordMeaning/issues/new?template=bug_report.yml).

**Nothing happens when I select text in a PDF**
The PDF must have a real text layer. Scanned/image-only PDFs have no selectable text, so there's nothing to look up (that would need OCR — not supported).

**The popup lingers after I switch tabs with the keyboard**
Switching tabs with **Ctrl+Tab** (keyboard) stays in the same window, so it isn't detected as a window switch. Click the tab instead, or just wait for the 6-second timer. (Clicking anywhere dismisses the popup immediately.)

**An AutoHotkey error dialog appeared**
Please [open a bug report](https://github.com/ishpreet36752/WordMeaning/issues/new?template=bug_report.yml) and paste the full error text.

## Limitations

- **English words only** (WordNet data).
- **Single words only** — no phrases or idioms.
- **Scanned/image PDFs** aren't supported (no text to select).
- Password fields and other non-copyable UI text are silently skipped.

## Contributing

Contributions are very welcome! See **[CONTRIBUTING.md](CONTRIBUTING.md)** for setup, tests, and conventions, and please follow our **[Code of Conduct](CODE_OF_CONDUCT.md)**.

Good first contributions: docs, extra troubleshooting entries, small quality-of-life options in `Config.ahk`.

## License

[MIT](LICENSE) — free to use, modify, and share.

The bundled dictionary is derived from **WordNet 3.1**, Princeton University — *WordNet 3.1 Copyright 2011 by Princeton University. All rights reserved.* ([licence](https://wordnet.princeton.edu/license-and-commercial-use))

The optional online fallback uses [Wiktionary](https://en.wiktionary.org/) via [FreeDictionaryAPI.com](https://freedictionaryapi.com/) ([CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)) and [api.datamuse.com](https://api.datamuse.com/). The same credit is in the app under tray → **About**.
