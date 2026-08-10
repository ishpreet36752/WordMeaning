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
**https://ishpreet36752.github.io/WordMeaning/**. The site is the shop window; the **GitHub Release
is the actual download path** — every Download button and the JSON-LD `downloadUrl`/`installUrl`
point at `github.com/ishpreet36752/WordMeaning/releases/latest/download/<asset>`.

That indirection exists for one reason: **GitHub counts Release-asset downloads and Pages counts
nothing.** Serving the binaries from `docs/downloads/` is unmeasurable. Keep every download link on
the release URLs or the counter silently undercounts.

`docs/downloads/` still holds committed copies of both binaries, now only as a mirror/fallback (this
is why those binaries are in git while `dist/` is ignored). `build.ps1` refreshes them as its last
step and prints the `gh release upload` command needed to publish a build to the buttons.

Read the counters with `.\scripts\download-stats.ps1` (needs `gh auth login`). It prints per-asset
and total downloads, plus the repo's 14-day traffic figures. **`gh release upload --clobber` deletes
and recreates the asset, which resets that asset's counter to zero** — cut a new tag per version
instead of clobbering, unless you are fixing a broken upload.

### Visitor counting

Pages exposes no logs, so a visit can only be counted by making a request to something that keeps
one. The page does that exactly once: a **GoatCounter no-JS pixel** just after `</footer>` in
`docs/index.html`, hitting `https://wordmeaning.goatcounter.com/count`. Stats live at
https://wordmeaning.goatcounter.com (login required; there is no API key anywhere in the repo).

Why the pixel and not the `<script src="//gc.zgo.at/count.js">` tag GoatCounter hands you on signup:
the scripted version collects screen size and links a session, and it puts third-party JavaScript on
a page that otherwise runs only its own. The pixel records a page view and referrer, sets no cookie,
and executes nothing. Cost of that choice: **the `p=` path is hardcoded**, fine for a one-page site —
if the site ever grows a second page, give it its own `p=` or its hits land on `/`.

Two properties to preserve if you touch it: it must **not** be `loading="lazy"` (a lazy 1x1 may never
enter the viewport, so the request never fires and the count silently stays flat), and ad blockers
drop it — the number is a floor, never inflated. Delete the one `<img>` and the page is fully
self-contained again.

Repo traffic (`scripts/download-stats.ps1`, or Insights → Traffic) is a *different* number: views of
the repository, not of the Pages site. Don't conflate them.

Apart from that pixel the landing page is a single self-contained file: inline CSS/SVG/JS, no other
external request, no webfonts, no third-party script. Its hero demo is driven by real `window.getSelection()` and deliberately
mirrors the app's behavior — `Config.WordPattern` verbatim, the 6s `TooltipTimeoutMs` auto-hide,
mousedown-hides/mouseup-resolves ordering, total silence on a multi-word selection (because
`Main.ahk` suppresses the `"not a single word"` error), the numbered two-sense layout, the quoted
example line, and the `Config.WebSearchHint` line on a miss. **If you change those behaviors in
`src/`, update the demo too** or the page starts teaching a gesture the program doesn't have.

### SEO / social

`docs/index.html` carries a canonical link, Open Graph + Twitter card tags, and a
`SoftwareApplication` JSON-LD block. All of them hardcode the absolute
`https://ishpreet36752.github.io/WordMeaning/` origin — **if the site ever moves to a custom domain,
update every one of them** (canonical, `og:url`, `og:image`, `twitter:image`, and the JSON-LD
`url`/`image`/`downloadUrl`/`installUrl`) plus `docs/sitemap.xml` and `docs/robots.txt`.

The social card is `docs/assets/og.png` (1200x630), generated by `scripts/make-og-image.ps1` — it
redraws the landing page's Win95 grammar in GDI+, so **regenerate it when the page's look or claim
changes**. Note: `Get-TextWidth`, not `Measure` — `measure` is an alias for `Measure-Object` and a
function by that name is shadowed.

`docs/robots.txt` is inert today: crawlers only read robots.txt at a domain root, and this site lives
at a `github.io` *subpath* owned by a different repo. It is committed so it starts working the moment
a custom domain makes `docs/` the root. `docs/sitemap.xml` is submitted directly in Search Console,
so it works either way — its `<lastmod>` is manual, bump it on substantive page edits.

The tray/app icon is `assets/wordmeaning.ico` (committed source asset; regenerate with `scripts/make-icon.ps1` if present). `build.ps1` embeds it via Ahk2Exe `/icon`; the uncompiled dev run loads it via `TraySetIcon` (`Main.SetTrayIcon`, guarded by `A_IsCompiled`).

## Architecture (modular — one responsibility per file)

- `src/Main.ahk` — entry point, wiring, tray menu, enable/disable state. Includes the other modules.
- `src/Config.ahk` — ALL tunables (timeouts, regex, API base, caps). Never hardcode values elsewhere.
- `src/SelectionWatcher.ahk` — global mouse hook. Detects drag-select or double-click, captures selection via clipboard-preserving Ctrl+C probe. Also fires an onPress callback so any click dismisses a stale popup.
- `src/FocusWatcher.ahk` — polls the active window id on a timer; fires onChange when the foreground window changes (Alt+Tab, app switch) so the popup is dismissed.
- `src/Dictionary.ahk` — freedictionaryapi.com client (Wiktionary data, no key) with an api.datamuse.com fallback. Input validation, HTTPS fetch, targeted field extraction, sense selection, session cache.
- `src/Popup.ahk` — tooltip display/hide, plus `IsVisible()` (gates the web-search hotkey).
- `src/Startup.ahk` — optional "run at login" toggle via the per-user `HKCU\...\Run` key. HKCU only (no admin, no machine-wide change); stores only the launch command, never any looked-up data.

Flow: SelectionWatcher → Main.OnSelection (word filter) → Dictionary.Lookup → Popup.Show.
Dismiss: SelectionWatcher.onPress (click) and FocusWatcher.onChange (window switch) → Popup.Hide; plus the 6s auto-hide timer.
Web fallback: `Config.WebSearchHotkey` is registered under `HotIf Popup.IsVisible()`, so it exists only while a popup is on screen and cannot shadow the same combination in the app being read.

### Sense selection (why the popup is not just "the first definition")

Wiktionary orders senses historically, so sense 1 is often useless (*juxtaposition: "the nearness of objects with little or no delimiter"*), while the best-scoring sense can be a deep subsense (*run: "to fuse, to shape, to mould"*). `Dictionary._Choose` therefore shows **the source's first sense AND the highest-scoring one**, both from the same part of speech. `_Score`: `+2` usable example, `-3` circular and unillustrated, `-1` domain-tagged, `-4` pointer sense ("Abbreviation of…"). `_Clean` strips grammatical tags (`(countable)`) but keeps subject tags (`(computing)`); `_IsLabel` drops Wiktionary grouping headings ("Terms relating to animals."); `_CleanExample` rejects literary citations and sub-4-word fragments rather than truncating them. Regression cases for all of this live in `tests/SmokeTest.ahk` — change the scoring and run it.

### AHK v2 gotcha (caused two load crashes — do not repeat)

Identifiers are **case-insensitive**. A `static` field must never share a name with a method (e.g. `_onPress` vs `_OnPress()`), or init fails with "Property is read-only". For OS/timer callbacks prefer a `.Bind(Class)` method + `SetTimer` (proven here) over `CallbackCreate`/`DllCall`, which hit `this`-binding ambiguity ("Invalid callback function").

## Invariants (do not break)

- **Clipboard is always restored** after the Ctrl+C probe, even on failure (`SelectionWatcher._CaptureSelection`).
- **Single-word only**: `Config.WordPattern` gates both the watcher callback and `Dictionary.Lookup`. Multi-word selections are silently ignored.
- **No pronunciation**: phonetic/audio fields from the API are deliberately never parsed or shown.
- **HTTPS only**, hosts pinned in `Config.ApiBase` and `Config.ApiFallbackBase`; the word is URL-encoded and length-capped (`MaxWordLen`) before any request. The fallback fires only when the primary has no entry.
- **The browser is never opened by the program itself** — only by the user pressing `Config.WebSearchHotkey` while a popup is up. Opening it hands the word to a search engine and writes it into browser history, which is exactly what the rest of the app avoids.
- **No API keys**: both sources are keyless, so nothing has to be shipped in the binary or written to disk.
- **Attribution**: the primary source is CC BY-SA 4.0. Credit stays in tray → About (`Config.AttributionText`) and in the site footer.
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
7. Select a word the dictionaries don't have (e.g. a product name) — popup shows the miss plus the hotkey hint; press Ctrl+Shift+D → browser opens a search for that word, popup closes.
8. Press Ctrl+Shift+D with no popup on screen — nothing happens (the app must not shadow that combination in other programs).
