# WordMeaning Landing Page — Design Brief / Engineered Prompt

Paste this whole document into a designer, another LLM, or use it as your own working brief. It is self-contained — no other context is assumed.

---

## 1. The task, in one line

Design a single-page site for **WordMeaning**, a Windows tray app that shows a word's definition in a small popup the instant you select it, then gets out of the way. The page's job is to make that two-second gesture felt before it's explained, then earn the click to download an unsigned `.exe` from a stranger.

---

## 2. Product context (don't skip — this constrains everything below)

- **What it does:** select a word in any Windows app (browser, PDF, Word) → a popup appears at the cursor with the word, part of speech, and a one-line definition → it disappears on its own after ~6 seconds. No pronunciation shown. Multi-word selections are ignored. Clipboard is always restored. Nothing is written to disk.
- **Primary audience:** non-technical Windows readers, mid-sentence, mid-focus. They are not shopping for a dictionary app; they want an interruption to stop being an interruption. Some read in a second language.
- **Secondary audience:** developers who arrive via GitHub to read the AutoHotkey v2 source. They should reach the repo without wading through marketing.
- **The real objection to overcome:** not "is this useful," but "will I regret running this." An unsigned executable, from a name they don't know, that watches selected text. Windows SmartScreen will actively warn them. The page has to survive that moment with specifics, not reassurance-words.
- **Brand personality:** calm, precise, unobtrusive — restraint as the actual feature. The product's defining trait is what it *doesn't* do: no pronunciation parsing, no persistence, no disk writes, auto-hide after 6s. Say "nothing is stored," never "privacy-first." Say "click More info → Run anyway," never "seamless installation."

---

## 3. Visual direction: Windows 95/98, used on purpose (not as a costume)

Pull the chrome from Windows 95/98: `#C0C0C0` grey surfaces, 2px beveled borders (light edge top/left, dark edge bottom/right — the classic `outset`/`inset` button look), title bars with a solid-color fill and a tight sans-serif label, square corners everywhere, no shadows except the hard 1px kind, system-font stack (Tahoma / MS Sans Serif fallback → a modern equivalent like "Pixelated MS Sans Serif" webfont or plain system-ui as fallback).

**Why this fits, and where to stop:** the product's actual UI *is* a native OS popup — it already has this exact bevel-and-grey vocabulary in real life. Using Win95 chrome isn't decoration, it's showing the reader their own desktop. That's the justification for going retro at all, and it's also the limit: the retro skin belongs on **interactive/demo elements** (buttons, window frames, the popup itself, the nav bar styled as a taskbar) — not smeared across body copy. Long-form text areas should stay closer to plain, high-contrast, quiet typography so the page doesn't read as a costume party. Loud chrome on controls, quiet paper underneath.

**Explicitly avoid**, per the product's own anti-references:
- Gradient hero washes, floating screenshot-on-glass, "Trusted by" logo walls — this is a solo open-source tray app, not a funded SaaS product.
- Mascots, blob shapes, confetti, bubble type.
- Black-background neon-monospace hacker theming — that's a different retro reference (CLI) and it alienates the non-technical primary audience. Win95 desktop chrome, not terminal cosplay.
- Turning the six real features into a checkmark wall. There are roughly six behaviors. Say them plainly once each.

---

## 4. Hero interaction: hybrid demo (auto-play → hover hand-off)

This is the single most important element on the page — per the product's own design principle, the interaction must be *shown*, not described, before a sentence of copy is read.

Build a small table like the reference screenshot (word / definition / short synonym, 3 rows visible), styled as a Win95 window with its own title bar (e.g. titled "dictionary.exe" or similar in-universe label).

**State machine:**
1. **Auto-play loop (default/idle state):** every ~4 seconds, one row's word gets the blue text-selection highlight, a small arrow/cursor glyph points at it, and the definition popup fades in beside it (styled exactly like the real product popup: tight padding, beveled border, word + part of speech + one-line definition), holds for ~2s, then clears and moves to the next row. Loops continuously.
2. **Hand-off on hover:** the moment a real visitor's cursor enters the table, the auto-play stops immediately (no fighting the visitor for control) and the popup instead follows whichever word their cursor is actually over — recreating the real product's live behavior. Moving the mouse out of the table resumes auto-play after a short pause (~2s), so the demo never sits dead for a visitor who's just passing through.
3. The auto-play cursor glyph should read as a *generic pointer*, not a branded mascot — same idea as the red arrow in the reference image, but restrained: a plain arrow, no cartoon hand.

**Accessibility override (non-negotiable, applies on top of the retro skin):**
- Full `prefers-reduced-motion: reduce` alternative: no auto-play movement; show one static row with its popup already open, or step on click only.
- The popup text must hit 4.5:1 contrast against its background — Win95 grey (`#C0C0C0`) is often too light for grey text; keep body/definition text dark enough regardless of the palette. Never let period-accuracy override this.
- Everything reachable and operable by keyboard: tab to a row, Enter/Space triggers the popup exactly like hover does.
- Selection-blue highlight is paired with the popup appearing — never rely on the blue alone to signal "this is the selected word" for anyone who can't perceive it as blue.

---

## 5. Page structure (one page, one conversion)

1. **Hero:** the interactive demo (above), one sentence of positioning under/beside it (plain, specific — e.g. what happens and what doesn't), one primary button styled as a Win95 button: **Download for Windows**.
2. **How it works:** three short beats max, each naming a real behavior (select → popup → auto-hide), no feature-wall.
3. **What it doesn't do (trust section):** the specifics that answer the SmartScreen moment head-on — HTTPS only, one pinned host, nothing written to disk, source is public, and a plain-language heads-up that Windows will show an "unrecognized app" warning and exactly which two clicks (More info → Run anyway) get past it. Show, don't sell.
4. **For developers:** one line, one link to GitHub. No separate visual campaign — same visual weight as a footnote, not a competing CTA.
5. **Footer:** minimal. No email capture, no cookie banner, no newsletter, no analytics-consent modal — the page should ask for nothing, matching the product asking for nothing.

Only one real call to action exists: the download. The GitHub link rides along without competing for attention.

---

## 6. Copy voice — do / don't

| Don't | Do |
|---|---|
| "Privacy-first, seamless, secure" | "Nothing is stored. Nothing is sent anywhere but the one dictionary host, over HTTPS." |
| "Effortless installation experience" | "Windows will warn you it's unrecognized — click More info, then Run anyway." |
| "Supercharge your reading" | "Select a word. See what it means. Keep reading." |
| Marketing adjectives stacked up | One plain sentence naming what actually happens |

---

## 7. Type & color starting point

- **Surface grey:** `#C0C0C0`, borders `#FFFFFF` (light edge) / `#808080` and `#000000` (dark edges), title bar accent one flat color (classic navy `#000080` works, or pick something quieter if navy reads too "corporate Windows").
- **Body copy:** off-white/paper background outside the chrome elements, dark near-black text, not pure black — but verified at 4.5:1 minimum.
- **Type:** system-ui stack with a period-accurate fallback (Tahoma/MS Sans Serif) for chrome labels and buttons only; body copy can use a more readable modern face at 1.6+ line height, 65–75ch measure, never justified.
- **No color-only signaling** anywhere — pair every state (hover, selected, active) with a shape or text change too.

---

## 8. Non-negotiables checklist

- [ ] Interaction is visible before any paragraph of copy
- [ ] Auto-play demo has a full reduced-motion fallback
- [ ] Retro chrome is on controls/frames, not smeared across body text
- [ ] Trust section states facts (HTTPS, one host, no disk writes, public source, SmartScreen steps) — no unsupported adjectives
- [ ] One primary CTA only; GitHub link is secondary, not a second campaign
- [ ] No account, email capture, cookie banner, or analytics wall
- [ ] All contrast ratios verified against actual rendered colors, not assumed from period-accuracy
