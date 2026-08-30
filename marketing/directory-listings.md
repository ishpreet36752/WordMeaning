# Directory listings

Submission copy for WordMeaning, one block per site. **Do not paste the same text twice.**
Directories deduplicate against each other and remove listings that read as copy-paste spam;
that is also why the descriptions below deliberately emphasise different things.

Facts that must stay true in every listing (check them before submitting, not after):

- Windows 10 and 11 only. AutoHotkey v2, so there is no macOS or Linux build.
- Free, MIT licence, no account, no ads, no telemetry, no API key.
- Offline by default: ~86,000 WordNet 3.1 entries compiled into the binary.
- Installer ~4.5 MB (per-user, no admin), portable single .exe ~9 MB.
- Nothing written to disk; clipboard restored after every lookup.
- Unsigned binary, so SmartScreen warns; releases carry a GitHub build provenance attestation.

Links to use:

- Site: https://ishpreet36752.github.io/WordMeaning/
- Source: https://github.com/ishpreet36752/WordMeaning
- Download (this URL is counted; a `docs/` mirror would not be):
  https://github.com/ishpreet36752/WordMeaning/releases/latest/download/WordMeaning-Setup.exe

Track submissions in the checklist at the end. One listing does little; twenty is the point.

---

## Launch platforms

### Product Hunt

**Name:** WordMeaning
**Tagline (60 chars max):** Select a word in any Windows app, see what it means
**Topics:** Productivity, Windows, Open Source, Education

**Description:**

> WordMeaning is a tray app for Windows that turns a double-click into a definition. Select one
> word in a browser, a PDF, Word or a chat window and the meaning appears at your cursor, then
> gets out of the way after six seconds.
>
> The whole dictionary — about 86,000 WordNet entries — is compiled into the 4.5 MB download, so
> it answers on a plane and on a locked-down machine. Nothing is written to disk, your clipboard
> comes back exactly as it was, and no request leaves the computer unless you switch on the
> optional online fallback yourself.

**First comment (maker):**

> I built this because checking one word cost me six actions and my place in the paragraph. The
> hard part was not the popup, it was making the dictionary offline: WordNet is packed into one
> sorted file that the program binary-searches in place, so a tray app can carry 86k entries
> without eating memory.
>
> It is MIT licensed and about 800 lines of AutoHotkey v2. The binaries are built by GitHub
> Actions with a provenance attestation, because "trust my .exe" is not an answer. Happy to talk
> about any of it, and the front page runs the real gesture in the browser if you want to try
> before downloading.

Launch-day notes: prepare the gallery images first (the OG image and two real screenshots), post
early in the day, and stay around to answer comments.

### Hacker News (Show HN)

**Title:** Show HN: WordMeaning – offline word-definition popup for Windows, 800 lines of AHK

**Body:**

> Select a single word anywhere in Windows and its definition appears at the cursor for six
> seconds. No window, no tab, no history.
>
> The interesting constraint was offline-first. The dictionary is a generated 7.5 MB file of
> ~86,000 WordNet 3.1 records, sorted, embedded as a resource in the .exe and binary-searched in
> place, so nothing is parsed at startup and nothing is written to disk. Irregular forms ship as
> redirect records; regular inflections are stripped by Morphy-style rules at lookup time.
>
> Sense selection was the other half of the work: WordNet orders senses historically, so sense 1
> is often the archaic one. The popup shows the first sense and the best-scoring sense from the
> same part of speech, and picks part of speech by tagged-corpus frequency rather than sense count.
>
> Limits, since they matter: English only, single words only, Windows only, and the corpus has no
> proper nouns or recent slang. The binary is unsigned so SmartScreen complains; releases are
> built in CI with a provenance attestation you can verify with gh.
>
> Source: https://github.com/ishpreet36752/WordMeaning

Be honest, do not oversell, and answer the "why not an extension" question directly: an extension
cannot reach a PDF reader or Word.

### Indie Hackers

Post in a relevant group rather than as an ad. Angle that fits the audience: the distribution
mechanics, not the feature list.

> I shipped a small Windows utility with no ads, no account and no server bill, and I wanted to
> know whether anyone was actually downloading it. GitHub counts release-asset downloads, GitHub
> Pages counts nothing, so every download button on the site points at the release URL rather than
> a copy of the binary in the repo. Visits are counted with a no-JS pixel. Total analytics cost:
> one image tag. Happy to share the numbers as they come in.

### BetaList

> WordMeaning is a Windows tray utility for people who read a lot on screen. Select any single
> word and its definition appears at the cursor, then vanishes. The dictionary is inside the
> program, so it works without a connection, and nothing you look up is stored anywhere.

### Uneed

> A word-definition popup for Windows that stays out of your way. Double-click a word in any app,
> read the meaning at your cursor, keep going. Free, open source, works offline.

### Fazier

> Reading something dense and hitting words you do not know? WordMeaning puts the definition where
> your eyes already are. It runs in the tray, works in every Windows app that lets you select
> text, and carries its own dictionary so there is nothing to sign up for.

### Microlaunch

> A tiny Windows app with one job: show me what this word means without making me leave the page.
> 4.5 MB, offline, MIT licensed, no account.

### Peerlist Project Spotlight

> WordMeaning — a system-wide dictionary popup for Windows, built in AutoHotkey v2. The whole
> WordNet corpus is embedded in the binary and binary-searched in place, so lookups need no
> network and no memory-hungry index. Releases are built in GitHub Actions with signed provenance.

---

## Software directories

### AlternativeTo

Highest intent of the lot: people arrive already looking to replace something.

**Listed as an alternative to:** Google Dictionary (browser extension), WordWeb, dictionary.com
**Tags:** dictionary, offline, portable, privacy-focused, open-source, tray-app, windows

> WordMeaning is a free, open-source dictionary popup for Windows. Unlike a browser extension it
> works everywhere you can select text — PDF readers, Word, email clients, chat apps — because it
> watches the selection at the OS level rather than inside a page. Definitions come from a WordNet
> corpus bundled in the download, so it needs no connection and no account, and looked-up words
> are never written to disk. Definitions only: there is no thesaurus, no pronunciation audio and
> no phrase lookup.

### MajorGeeks

Include the SmartScreen note; their audience expects it.

> A 4.5 MB tray utility that shows the meaning of any word you select, anywhere in Windows. The
> dictionary (about 86,000 WordNet entries) is inside the executable, so it runs offline and needs
> no AutoHotkey install. Per-user setup, no administrator rights, and a portable single-file build
> for a USB stick. Open source under the MIT licence; the binary is unsigned, so Windows
> SmartScreen shows its usual first-run warning.

### Softpedia (Windows)

Softpedia editors test what they list, so keep this precise and unhyped.

> WordMeaning is a lightweight system tray application that displays English word definitions in a
> tooltip at the mouse cursor. Selecting a single word by double-click or drag in any application
> that supports text selection triggers a lookup against a WordNet 3.1 dictionary embedded in the
> executable; the tooltip shows the part of speech, up to two senses and an example sentence, and
> closes on click, window switch or after six seconds. Multi-word selections are ignored. The
> clipboard is preserved. No data is written to disk and no network connection is required or
> made, unless the optional online fallback is enabled from the tray menu. Installer and portable
> builds are provided.

### Uptodown (Windows)

> Look up any English word without stopping what you are reading. WordMeaning waits in the Windows
> system tray, and a double-click on a word in any program brings up its meaning right where the
> cursor is. It carries its own dictionary of about 86,000 entries, so it works with no internet
> connection, and it is completely free.

### Slant ("What are the best dictionary tools for Windows?")

Answer the question as a recommendation with the honest downside, which is how Slant works.

> **Pro:** Works in every application, not just the browser, because it hooks text selection at
> the OS level.
> **Pro:** Fully offline — the WordNet corpus is compiled into the binary, so there is no API to
> disappear and no lookup leaving your machine.
> **Pro:** Stores nothing. No history file, no log, and the clipboard is restored after each use.
> **Con:** English only, single words only, no thesaurus and no pronunciation.
> **Con:** The corpus is fixed, so proper nouns and new slang are missing; misses fall back to a
> manual web search on Ctrl+Shift+D.
> **Con:** Unsigned binary, so SmartScreen warns on first launch.

### SaaSHub

> An open-source alternative to browser dictionary extensions and commercial desktop dictionaries.
> WordMeaning is a Windows tray app that shows a definition at your cursor when you select a word
> in any program. It ships its own offline dictionary, has no account, no subscription and no
> telemetry, and is MIT licensed.

### The Portable Freeware Collection

> Portable single-file build (~9 MB) containing the program and its entire dictionary. Run it from
> a USB stick with no installation; it writes nothing outside itself unless you enable the
> "Start with Windows" tray toggle, which sets a per-user registry Run value. Shows definitions
> for words selected in any application.

### GitHub discovery (free, and it compounds)

- Repo topics: `windows`, `autohotkey`, `autohotkey-v2`, `dictionary`, `wordnet`, `offline`,
  `tray-application`, `productivity`, `portable`, `privacy`.
- Submit to the relevant `awesome-*` lists (awesome-windows, awesome-autohotkey, awesome-privacy)
  following each list's contribution rules.

---

## Reddit

Read each subreddit's self-promotion rules first, and be a participant before you post. Mods
remove app posts fast, and a removed post costs the account, not just the thread.

- **r/software** — "I made a free offline dictionary popup for Windows". Lead with the limits.
- **r/windows** — frame it as a utility, not a launch.
- **r/AutoHotkey** — the technical audience: embedded resource dictionary, in-place binary search,
  the case-insensitive-identifier gotcha that cost two load crashes.
- **r/coolgithubprojects** — repo link, one-line description, MIT licence.
- **r/PDF** or study-focused subs — only where the PDF-reading angle is genuinely on topic.

---

## Also do this

- Submit `docs/sitemap.xml` in **Google Search Console** (the property is already verified by the
  `google-site-verification` meta tag in `docs/index.html`).
- Add the site to **Bing Webmaster Tools**, easiest by importing from Search Console. Bing's index
  is what ChatGPT search reads, so this is not optional any more.
- Ping **IndexNow** after publishing or editing a page: `.\scripts\submit-indexnow.ps1`.
- Read the counters with `.\scripts\download-stats.ps1` (needs `gh auth login`) and the visit
  numbers at https://wordmeaning.goatcounter.com. Do not confuse repo traffic with site visits.

## Checklist

| Site | Submitted | Live | Notes |
|---|---|---|---|
| Product Hunt | | | prepare gallery images first |
| Hacker News (Show HN) | | | one attempt, weekday morning US time |
| Indie Hackers | | | group post, not an ad |
| BetaList | | | |
| Uneed | | | |
| Fazier | | | |
| Microlaunch | | | |
| Peerlist | | | |
| AlternativeTo | | | highest intent |
| MajorGeeks | | | |
| Softpedia | | | editor-reviewed |
| Uptodown | | | |
| Slant | | | answer an existing question |
| SaaSHub | | | |
| Portable Freeware | | | portable build only |
| awesome-* lists | | | follow each list's rules |
| r/software | | | |
| r/windows | | | |
| r/AutoHotkey | | | |
| r/coolgithubprojects | | | |
