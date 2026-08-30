# WordMeaning

System-wide word-definition popup. Select a single word in any app (browser, PDF reader, Word) → definition tooltip appears at the cursor.

Two native apps, one dictionary and one set of rules:
- **Windows** (`src/`, AutoHotkey v2) — the original, shipped and tested.
- **macOS** (`mac/`, Swift + AppKit) — a port, **compiled and unit-tested in CI but never yet run on a real Mac**. Treat it as a preview until someone has worked through the manual matrix below.

Both read the same generated `assets/dictionary.dat` and answer with the same senses; behaviour values live in `src/Config.ahk` and `mac/Sources/WordMeaningCore/Config.swift`, which must be changed together.

## Run

```powershell
.\scripts\build-dictionary.ps1   # once — generates assets\dictionary.dat (git-ignored)
.\run.ps1
```

(`run.ps1` finds AutoHotkey v2 in user-scope `%LOCALAPPDATA%\Programs\AutoHotkey` or machine-scope `Program Files`.) Runs in the system tray. Tray menu: Enabled (toggle), Start with Windows (toggle), Look up missing words online (toggle, off by default), About, Exit.

## Build a standalone .exe

```powershell
.\build.ps1
```

Produces `dist/WordMeaning.exe` (single file — all modules, the tray icon, and the whole dictionary embedded). Runs on any Windows PC with **no AutoHotkey install, no source files present, and no internet connection** — copy it anywhere as a portable backup. `build.ps1` refuses to start if `assets/dictionary.dat` is missing, because Ahk2Exe resolves the resource at compile time. Needs the Ahk2Exe compiler at `%LOCALAPPDATA%\Programs\AutoHotkey\Compiler\Ahk2Exe.exe` (install via `UX\install-ahk2exe.ahk` or unzip a release from github.com/AutoHotkey/Ahk2Exe).

If [Inno Setup](https://jrsoftware.org/isdl.php) is installed (`%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe`), `build.ps1` also compiles `installer/WordMeaning.iss` into `dist/WordMeaning-Setup.exe` — a per-user installer (no admin) with Start-menu + optional desktop shortcut, an optional "Start with Windows" checkbox (writes the same HKCU Run key as the tray toggle), and a clean uninstaller. `dist/` is git-ignored — it is a build artifact, regenerate with `build.ps1`.

## Website / distribution

The download site is published by GitHub Pages from `main` + `/docs` at
**https://ishpreet36752.github.io/WordMeaning/**. `docs/index.html` is the landing page; four article
pages answer one search intent each (`offline-dictionary-windows.html`,
`look-up-words-while-reading.html`, `dictionary-popup-for-pdf-windows.html`,
`dictionary-popup-alternatives-windows.html`) and share `docs/assets/article.css` — `index.html` keeps
its own CSS inline, so it stays the one page that is a single self-contained file. The site is the
shop window; the **GitHub Release is the actual download path** — every Download button and the JSON-LD `downloadUrl`/`installUrl`
point at `github.com/ishpreet36752/WordMeaning/releases/latest/download/<asset>`.

That indirection exists for one reason: **GitHub counts Release-asset downloads and Pages counts
nothing.** Serving the binaries from `docs/downloads/` is unmeasurable. Keep every download link on
the release URLs or the counter silently undercounts.

**Nothing compiled or generated is committed.** `dist/` and `assets/dictionary.dat` are git-ignored.
`docs/downloads/` used to hold committed copies of both binaries as a mirror; it was deleted, because
a binary in the tree is one nobody can trace to a commit.

Releases are built by `.github/workflows/release.yml`, triggered by pushing a `v*` tag — not uploaded
by hand. It pins and checksums AutoHotkey and Ahk2Exe, generates the dictionary, runs the suite plus
the compiled-resource check, calls the same `build.ps1` a maintainer runs locally, and attaches an
`actions/attest-build-provenance` attestation so a download can be verified:

```powershell
gh attestation verify WordMeaning.exe --repo ishpreet36752/WordMeaning
```

That verification is the answer to "why should I trust this .exe", so **keep the release path going
through CI**. A hand-uploaded asset has no attestation and quietly breaks the claim the README and
the landing page both make.

Read the counters with `.\scripts\download-stats.ps1` (needs `gh auth login`). It prints per-asset
and total downloads, plus the repo's 14-day traffic figures. **`gh release upload --clobber` deletes
and recreates the asset, which resets that asset's counter to zero** — cut a new tag per version
instead of clobbering, unless you are fixing a broken upload.

### Visitor counting

Pages exposes no logs, so a visit can only be counted by making a request to something that keeps
one. Each page does that exactly once: a **GoatCounter no-JS pixel** just after `</footer>`, hitting
`https://wordmeaning.goatcounter.com/count`. Stats live at
https://wordmeaning.goatcounter.com (login required; there is no API key anywhere in the repo).

Why the pixel and not the `<script src="//gc.zgo.at/count.js">` tag GoatCounter hands you on signup:
the scripted version collects screen size and links a session, and it puts third-party JavaScript on
a page that otherwise runs only its own. The pixel records a page view and referrer, sets no cookie,
and executes nothing. Cost of that choice: **the `p=` path is hardcoded per page**. Every page carries
its own pixel with its own `p=` (`%2Foffline-dictionary-windows` and so on) — copy a page without
changing it and its hits are silently filed under the page you copied.

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

The article pages add exactly one same-origin request each (`assets/article.css`) and run no
JavaScript at all. Each opens with a short `.answer` block that answers its own headline in full —
that paragraph is what a search snippet or an AI overview quotes, so keep it self-contained and
true. Each also carries a visible FAQ whose wording matches its `FAQPage` JSON-LD; **change one and
change the other**, because schema that disagrees with the page is a manual-action risk, not a
ranking trick.

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

Every page also carries `robots` = `index,follow,max-snippet:-1,max-image-preview:large`, so an
overview may quote the whole answer paragraph rather than a truncated fragment.

`docs/llms.txt` is the plain-text brief for AI crawlers and assistants: what the program is, the
facts, and — deliberately — the limits, so an assistant that reads it does not invent a thesaurus or
a Mac build. **It is written by hand; update it when a claim on the site changes.**

New page checklist (all four steps, or the page is invisible or miscounted):
1. Own `p=` in its GoatCounter pixel.
2. Own canonical, `og:url`, title and description.
3. Added to `docs/sitemap.xml`, with `<lastmod>` bumped.
4. `.\scripts\submit-indexnow.ps1` after it is live, plus a link from at least one existing page.

`scripts/submit-indexnow.ps1` pings IndexNow (Bing, Yandex, Seznam — not Google, which ignores it;
Bing matters because ChatGPT search reads its index). Ownership is the key file
`docs/9a1cfd86bf22913fb2d927b51f92a7fe.txt`, which must keep serving exactly that key: it sits in a
subdirectory rather than a host root, so it authorises only URLs under `/WordMeaning/` and every
request must send `keyLocation`. Rename or delete it and submissions fail with 403.

`marketing/` is not published — `seo-notes.md` records what the distribution playbook asked for and
which parts need a human with a login, and `directory-listings.md` holds per-directory submission
copy. Its rule: **never paste the same description twice**, because directories deduplicate and
remove listings that read as copy-paste.

`docs/robots.txt` is inert today: crawlers only read robots.txt at a domain root, and this site lives
at a `github.io` *subpath* owned by a different repo. It is committed so it starts working the moment
a custom domain makes `docs/` the root. `docs/sitemap.xml` is submitted directly in Search Console,
so it works either way — its `<lastmod>` is manual, bump it on substantive page edits.

The tray/app icon is `assets/wordmeaning.ico` (committed source asset; regenerate with `scripts/make-icon.ps1` if present). `build.ps1` embeds it via Ahk2Exe `/icon`; the uncompiled dev run loads it via `TraySetIcon` (`Main.SetTrayIcon`, guarded by `A_IsCompiled`).

## macOS build (`mac/`)

```bash
pwsh ./scripts/build-dictionary.ps1   # once — pwsh runs the same generator on macOS
swift test  --package-path mac        # the core suite: dictionary, senses, wrapping
swift build --package-path mac        # quick compile
./mac/build-mac.sh 1.2.0              # WordMeaning.app + WordMeaning.dmg in mac/dist/
```

SwiftPM, two targets on purpose: `WordMeaningCore` is pure logic with no AppKit, so CI can run the
suite headlessly; `WordMeaning` is the AppKit shell. `build-mac.sh` assembles the bundle by hand
(SwiftPM does not build .app bundles), builds a universal arm64+x86_64 binary, extracts the icon from
the Windows `.ico` with `mac/ico2png.py` (stdlib only — a build that has to `pip install` to draw an
icon breaks on the next runner image), and **always signs, ad-hoc if there is no Developer ID**:
Apple Silicon refuses to launch a completely unsigned binary.

Module map, and its Windows counterpart:

| macOS | Windows | Notes |
|---|---|---|
| `Sources/WordMeaningCore/Config.swift` | `src/Config.ahk` | same numbers, same regex |
| `Sources/WordMeaningCore/LocalDictionary.swift` | `src/LocalDictionary.ahk` | same file format, same in-place binary search, same Morphy rules |
| `Sources/WordMeaningCore/DictionaryService.swift` | `src/Dictionary.ahk` | named "Service" because `Dictionary` is a Swift type |
| `Sources/WordMeaningCore/TextWrap.swift`, `PopupText.swift` | `src/Popup.ahk`, `Main.OnSelection` | lifted out so both platforms format a result identically |
| `Sources/WordMeaning/SelectionWatcher.swift` | `src/SelectionWatcher.ahk` | Accessibility API first, Cmd+C probe second |
| `Sources/WordMeaning/FocusWatcher.swift` | `src/FocusWatcher.ahk` | a workspace notification, not a poll |
| `Sources/WordMeaning/Popup.swift` | `src/Popup.ahk` | non-activating NSPanel; vibrancy gives Dark Mode free |
| `Sources/WordMeaning/LoginItem.swift` | `src/Startup.ahk` | `SMAppService`, the per-user equivalent of the HKCU Run key |
| `Sources/WordMeaning/WebSearchHotkey.swift` | `Main.InitWebSearchHotkey` | Carbon hot key, registered only while a popup is up |
| `Sources/WordMeaning/AppDelegate.swift` | `src/Main.ahk` | wiring, menu bar, enable/disable |

### Where the platforms deliberately differ

- **Reading the selection.** macOS has a real API for it: `kAXSelectedTextAttribute` on the focused
  element, so the normal path never touches the pasteboard at all — strictly better than the Windows
  Ctrl+C probe. Apps that do not expose it fall back to a Cmd+C probe that saves and restores the
  pasteboard. **The restore-always invariant applies to that fallback exactly as it does on Windows.**
- **Accessibility permission.** Nothing can watch events or read another app's selection until the
  user grants it in System Settings → Privacy & Security → Accessibility. The app launches into a
  waiting state, shows a "Grant Accessibility access…" item, and starts watching the moment the right
  appears (it polls, because macOS sends no notification for it). There is no Windows equivalent.
- **Dismiss on app switch** is a `NSWorkspace.didActivateApplicationNotification`, not a 250 ms poll.
  Same granularity caveat: switching windows or tabs inside one app is not an app switch, so that
  case is covered by click-to-dismiss and the 6 s timer.
- **The hot key is ⌘⇧D**, not Ctrl+Shift+D, and it is a Carbon hot key rather than an NSEvent monitor
  **because a monitor cannot swallow the key** — the combination would still reach the app underneath.
  Registered on popup show, unregistered on hide, which is what `HotIf Popup.IsVisible()` buys on Windows.
- **Gatekeeper is harsher than SmartScreen.** Without a Developer ID the .dmg needs right-click → Open
  (or clearing the quarantine attribute). `release.yml` signs and notarizes when `APPLE_CERTIFICATE_P12`,
  `APPLE_CODESIGN_IDENTITY`, `APPLE_NOTARY_ID`, `APPLE_NOTARY_PASSWORD` and `APPLE_TEAM_ID` are set as
  repository secrets, and quietly builds unsigned when they are not. Adding them later changes nothing else.

### macOS testing

`swift test --package-path mac` runs the mirror of `DictTest` plus the sense-selection regressions
that `SmokeTest.ahk` needs a network for on Windows (the online sources are replaced by a stub that
replays recorded bodies, and one test asserts **no request is made while the fallback is off**).
CI additionally assembles the .app and checks it carries `dictionary.dat`, an icon, `LSUIElement`,
a valid signature and both architectures.

**No automated coverage exists for the parts that need a Mac**: the event monitors, the AX read, the
pasteboard fallback, popup placement, the permission prompt, the login item. Manual matrix, to run
once on real hardware before the download is advertised anywhere:

1. Grant Accessibility, then double-click a word in Safari, Chrome and Preview → popup at the cursor.
2. Drag-select a word in a PDF with a text layer → popup. Scanned PDF → nothing, no error.
3. Notes/TextEdit/Slack → both select methods.
4. Copy something, look a word up, paste → the original clipboard must be intact (this exercises the
   Cmd+C fallback only in apps with no AX text; check one of each).
5. Select a whole sentence → no popup, no error.
6. Turn off wifi, look up a dozen words → all resolve.
7. Miss a word → popup shows the hint; ⌘⇧D opens the browser and closes the popup.
8. ⌘⇧D with no popup on screen → nothing happens, and the key still reaches the app underneath.
9. Menu bar: Enabled off → no popups; Start at Login on → survives a logout; online fallback on →
   *selfie* resolves, off again → it misses again.
10. Quit → the status item disappears and no process is left behind.

## Architecture (modular — one responsibility per file)

- `src/Main.ahk` — entry point, wiring, tray menu, enable/disable state. Includes the other modules.
- `src/Config.ahk` — ALL tunables (timeouts, regex, dictionary paths, API base, caps). Never hardcode values elsewhere.
- `src/SelectionWatcher.ahk` — global mouse hook. Detects drag-select or double-click, captures selection via clipboard-preserving Ctrl+C probe. Also fires an onPress callback so any click dismisses a stale popup.
- `src/FocusWatcher.ahk` — polls the active window id on a timer; fires onChange when the foreground window changes (Alt+Tab, app switch) so the popup is dismissed.
- `src/LocalDictionary.ahk` — the bundled dictionary. Binary-searches the packed data in place (no Map, no full parse), follows irregular-form redirects, and strips regular inflections by rule.
- `src/Dictionary.ahk` — validation, sense selection, session cache, and lookup routing: local first, network only if the user switched the fallback on. Also still holds the HTTPS clients (freedictionaryapi.com + api.datamuse.com) and their parsers.
- `src/Popup.ahk` — tooltip display/hide, plus `IsVisible()` (gates the web-search hotkey).
- `src/Startup.ahk` — optional "run at login" toggle via the per-user `HKCU\...\Run` key. HKCU only (no admin, no machine-wide change); stores only the launch command, never any looked-up data.

Flow: SelectionWatcher → Main.OnSelection (word filter) → Dictionary.Lookup → Popup.Show.
Dismiss: SelectionWatcher.onPress (click) and FocusWatcher.onChange (window switch) → Popup.Hide; plus the 6s auto-hide timer.
Web fallback: `Config.WebSearchHotkey` is registered under `HotIf Popup.IsVisible()`, so it exists only while a popup is on screen and cannot shadow the same combination in the app being read.

### The bundled dictionary (why lookups need no network)

A dictionary that makes an HTTPS request per word is a dictionary that fails on a plane, depends on
someone else's uptime, and asks the user to trust a host. The whole corpus now ships inside the
program and **the network is off by default**.

`scripts/build-dictionary.ps1` generates `assets/dictionary.dat` from a checksum-pinned **WordNet
3.1** release (`wordnetcode.princeton.edu`, cached under `.staging/`, ~90 s). Output: ~86k records,
7.5 MB, one per line, tab-separated, **sorted ordinally**, no BOM, `\n` endings:

```
key <TAB> pos <TAB> definition <TAB> altDefinition <TAB> example
key <TAB> =   <TAB> targetWord                              (irregular form)
```

`#` comment lines sit at the top and cost nothing — `#` (0x23) sorts before any key, which always
starts with a letter.

`LocalDictionary` binary-searches those bytes **in place**: probe a byte offset, nudge forward to the
next `\n`, compare. It never builds a Map — 86k entries would cost far more RAM than a tray app
should. Comparison is **byte-ordinal** (`_Compare`), deliberately *not* AHK's `<`, which is
case-insensitive and would disagree with the sort order the file was written in. Change the sort in
the generator and you must change `_Compare` with it.

Two loading paths, and only one of them is reachable from a plain script run:
- **compiled** — the data is an RT_RCDATA resource (`;@Ahk2Exe-AddResource *10 ..\assets\dictionary.dat, DICT` in `Main.ahk`). `LockResource` hands back a pointer into the mapped image, so nothing is copied and **nothing is written to disk** — the portable build stays one file.
- **source run** — `FileRead(..., "RAW")`. The Buffer is held in a static because the pointer dies with it.

`tests/DictTest.ahk` covers the file path; only `scripts/test-compiled.ps1` covers the resource path,
which is the one every download uses. Run it after touching either.

Inflections split by cost: **irregulars** ("ran", "mice") ship as redirect records from WordNet's
`.exc` files; **regular** forms are stripped at lookup time by Morphy-style rules in
`LocalDictionary._rules`, which cost no bytes. Rules are tried longest-suffix-first and only after an
exact miss, so a real headword is never mangled ("as" stays "as"). A word with no entry can still
resolve through its root (*delimiter* → *delimit*) — the popup shows the word it resolved to, so
nothing is misattributed.

Part of speech comes from `cntlist.rev` corpus frequencies, not sense counts: *better* has more verb
senses than adjective ones, but the tagged corpora put the adjective ahead 92 to 3.

`Config.OnlineFallbackDefault` is `false` and the tray toggle is **session-only, never persisted** —
enabling the network should be a decision the user re-makes, not one a config file makes for them.
Toggling it clears the cache (`Dictionary.ClearCache`), or words that missed while offline stay
missed for the session.

### Sense selection (why the popup is not just "the first definition")

Both online sources order senses historically, so sense 1 is often useless (*juxtaposition: "the nearness of objects with little or no delimiter"*), while the best-scoring sense can be a deep subsense (*run: "to fuse, to shape, to mould"*). `Dictionary._Choose` therefore shows **the source's first sense AND the highest-scoring one**, both from the same part of speech. `_Score`: `+2` usable example, `-3` circular and unillustrated, `-1` domain-tagged, `-4` pointer sense ("Abbreviation of…"). `_Clean` strips grammatical tags (`(countable)`) but keeps subject tags (`(computing)`); `_IsLabel` drops Wiktionary grouping headings ("Terms relating to animals."); `_CleanExample` rejects literary citations and sub-4-word fragments rather than truncating them. Regression cases for all of this live in `tests/SmokeTest.ahk` — change the scoring and run it.

The generator applies the **same rules ahead of time** (`Get-SenseScore`, the example-length and
sub-4-word drops, `_Result`'s "drop the second sense rather than shrink it" budget), so offline and
online answers are shaped alike. Change the scoring in `Dictionary` and change it in
`scripts/build-dictionary.ps1` too, or the two sources start disagreeing about what a good sense is.

### AHK v2 gotcha (caused two load crashes — do not repeat)

Identifiers are **case-insensitive**. A `static` field must never share a name with a method (e.g. `_onPress` vs `_OnPress()`), or init fails with "Property is read-only". For OS/timer callbacks prefer a `.Bind(Class)` method + `SetTimer` (proven here) over `CallbackCreate`/`DllCall`, which hit `this`-binding ambiguity ("Invalid callback function").

## What is not in the repository (and why)

`.gitignore` carries the reasons inline; this is the summary, because "why is this not committed?"
is asked far more often than it is answered.

| Not committed | Why | How to get it back |
|---|---|---|
| `dist/`, `mac/dist/`, `mac/.build/` | Compiled output. A binary in the tree is one nobody can trace to a commit; the ones people download are built by CI with an attestation | `.uild.ps1` / `bash mac/build-mac.sh` |
| `assets/dictionary.dat` | Generated from a checksum-pinned WordNet release, so it is reproducible rather than stored | `.\scriptsuild-dictionary.ps1` (`pwsh` on macOS) |
| `.staging/` | Download cache for the corpus and pinned tools | regenerated on demand |
| `/*.pdf` | Reference material written by other people. Reading it and summarising it in `marketing/seo-notes.md` is fair; re-hosting the file publicly is not ours to do | keep your own copy locally |
| `plan.md`, `wordmeaning-landing-page-brief.md`, `notes.md`, `scratch/` | Working drafts belonging to whoever is working. Anything meant to last belongs in `README.md`, `CLAUDE.md`, `PRODUCT.md` or `marketing/` | n/a |
| `.claude/settings.local.json`, `.vscode/`, `.idea/` | Per-machine tool state: paths and permissions that are wrong on anyone else's machine | n/a |
| `.DS_Store`, `Thumbs.db` | OS litter | n/a |

Committed on purpose, despite looking like it should not be:

- **`docs/9a1cfd86bf22913fb2d927b51f92a7fe.txt`** — the IndexNow key. It proves ownership only by
  being served from the site, so it *must* be published. It authorises URL submission and nothing
  else; it is not a credential and grants no access to anything.
- **`assets/wordmeaning.ico`** — a source asset, not build output. The Mac icon is derived from it.
- **`marketing/`** — plain text, no keys. It is versioned because the listing copy has to stay in
  step with what the app actually does.

There are **no secrets in this repository at all**: every dictionary source is keyless, GoatCounter
stats need a login that lives nowhere here, and the Apple signing material exists only as GitHub
Actions secrets referenced by name in `release.yml`.

## Invariants (do not break)

- **Clipboard is always restored** after the Ctrl+C probe, even on failure (`SelectionWatcher._CaptureSelection`; on macOS `SelectionWatcher.pasteboardProbe`, which is only reached when the Accessibility read fails).
- **Single-word only**: `Config.WordPattern` gates both the watcher callback and `Dictionary.Lookup`. Multi-word selections are silently ignored.
- **No pronunciation**: phonetic/audio fields from the API are deliberately never parsed or shown.
- **Offline by default**: a lookup is answered from `LocalDictionary`. No socket is opened unless the user turns the tray fallback on. This is the headline claim on the site and in the README — do not make the network the default to fix a coverage gap.
- **HTTPS only** when the fallback *is* on, hosts pinned in `Config.ApiBase` and `Config.ApiFallbackBase`; the word is URL-encoded and length-capped (`MaxWordLen`) before any request. The secondary fires only when the primary has no entry.
- **The browser is never opened by the program itself** — only by the user pressing `Config.WebSearchHotkey` while a popup is up. Opening it hands the word to a search engine and writes it into browser history, which is exactly what the rest of the app avoids.
- **No API keys**: every source is keyless, so nothing has to be shipped in the binary or written to disk.
- **Attribution**: WordNet's copyright notice must be reproduced, and the optional primary online source is CC BY-SA 4.0. Credit stays in tray → About (`Config.AttributionText`), the README, and the site footer.
- **Nothing compiled or generated in git**: `dist/`, `assets/dictionary.dat`. Binaries reach users only as CI-built, attested release assets.
- **No persistence**: looked-up words live only in the in-memory session cache (`CacheMaxEntries` cap). Nothing is written to disk or logged.
- **Deterministic behavior**: same word → same cached result within a session; all timing values come from `Config`.
- **The two platforms answer alike**: a behaviour change in `src/` is not finished until the same change is in `mac/Sources/WordMeaningCore/`, and the reverse. The shared contract is `Config` (numbers, regex), the dictionary format, and the sense-selection rules.

## Conventions

- AutoHotkey v2 syntax only (`#Requires AutoHotkey v2.0` in every file).
- Static classes as modules; state kept in class statics, except `enabled` (Main-level global).
- Errors surface as `{ ok: false, error: "…" }` result objects, never thrown across module boundaries.

## Testing

Everything below needs `assets/dictionary.dat`, which is generated, not committed. Build it once:
`.\scripts\build-dictionary.ps1`.

Automated:
- `tests/LoadTest.ahk` — includes every module so all class static-initializers run; catches load-time faults like the case-insensitive name collision above. No network needed.
- `tests/DictTest.ahk` — the bundled dictionary: binary search across the file (first record, last record, spread of keys), record shape, frequency-chosen part of speech, irregular + regular inflections, headword-beats-stripping, clean misses. No network.
- `tests/WrapTest.ahk` — deterministic Popup word-wrapping checks. No network.
- `tests/StartupTest.ahk` — exercises the HKCU Run-key auto-start toggle end to end; leaves the registry clean afterward. No network.
- `tests/SmokeTest.ahk` — the **optional online fallback only**: that it stays off by default, that a word absent offline (*selfie*) resolves once it is on, and the API parsers' regressions via `Dictionary._Fetch`. The only test that touches the internet.
- `tests/ResourceTest.ahk` + `scripts/test-compiled.ps1` — compiles a probe and runs it to prove the .exe reads its embedded dictionary. **No plain-script test can reach that code path**, and it is the one every download uses.

```powershell
$ahk = "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
& $ahk /ErrorStdOut tests\LoadTest.ahk     # expect: LOAD OK
& $ahk /ErrorStdOut tests\DictTest.ahk     # expect: ALL PASS
& $ahk /ErrorStdOut tests\WrapTest.ahk     # expect: ALL PASS
& $ahk /ErrorStdOut tests\StartupTest.ahk  # expect: ALL PASS
& $ahk /ErrorStdOut tests\SmokeTest.ahk    # expect: ALL PASS  (needs internet)
.\scripts\test-compiled.ps1                # expect: ALL PASS  (needs Ahk2Exe)
```

CI (`.github/workflows/ci.yml`) runs everything except `SmokeTest` on push/PR in the `windows` job, and
builds plus tests the Swift port in the `macos` job; `release.yml` adds the compiled check before it
builds, and publishes the Mac `.dmg` alongside the Windows assets.

Note: `LoadTest` only runs static initializers, not `Start()` methods. To catch errors inside a watcher's `Start()` (e.g. bad callback setup), run `src/Main.ahk` with stderr captured — clean means the process stays alive AND stderr is empty (a lingering error dialog is itself an `AutoHotkey64.exe` process, so a bare pid check is not proof of a clean load).

Hook/UI code has no automated coverage. Manual test matrix after any change:
1. Chrome webpage — double-click a word → popup shows meaning, no pronunciation.
2. PDF with text layer (Edge or Adobe) — drag-select a word → popup.
3. Word/Notepad — both select methods.
4. Copy something first, do a lookup, paste — original clipboard must be intact.
5. Select a full sentence — no popup, no error.
6. Disconnect the network entirely, then look up a dozen ordinary words — every one must resolve exactly as before. This is the whole point; check it on the compiled .exe, not just a source run.
7. Select a word the dictionary doesn't have (e.g. a product name) — popup shows the miss plus the hotkey hint; press Ctrl+Shift+D → browser opens a search for that word, popup closes.
8. Press Ctrl+Shift+D with no popup on screen — nothing happens (the app must not shadow that combination in other programs).
9. Tray → Look up missing words online, then select a word absent offline (e.g. *selfie*) — resolves. Disconnect the network and repeat — "offline / network error" popup, no crash. Switch the toggle back off — the same word misses again (the cache is cleared with the toggle).
