# Product

## Register

product

## Users

**Primary — everyday Windows readers.** Non-technical people reading articles in Chrome, PDFs in Edge, documents in Word. They hit an unfamiliar word mid-sentence and don't want to break reading flow by opening a tab, typing the word, and losing their place. They are not looking for a dictionary app; they want the interruption to stop being an interruption.

Their moment of doubt is the download, not the product: an unsigned `.exe`, from a developer they've never heard of, that watches what text they select. Whatever the page does, it has to survive that suspicion.

**Secondary — developers and tinkerers.** They arrive via GitHub, read the AutoHotkey v2 source, and may fork, file issues, or contribute. They should never have to wade through marketing to reach the code.

## Product Purpose

WordMeaning is a system-wide single-word definition popup for Windows. Select a word in any app — browser, PDF reader, Word — and its definition appears at the cursor, then disappears on its own.

It exists because looking up a word costs more attention than the lookup is worth: copy, switch app, paste, search, scan, come back, find your place again. WordMeaning collapses that to one gesture.

Success looks like someone installing it, forgetting it is running, and simply no longer opening dictionary tabs.

## Brand Personality

**Calm, precise, unobtrusive.** *(Inferred from the codebase's own invariants — correct me if this is off.)*

The character is already written into the code as deliberate omissions: pronunciation is never parsed or shown, multi-word selections are silently ignored, the clipboard is always restored, nothing is written to disk, the popup auto-hides after six seconds. The product's defining trait is restraint — it does one thing and leaves no trace.

Voice: plain and specific, never salesy. Say "nothing is stored," not "privacy-first." Say "click More info → Run anyway," not "seamless installation." Name what happens; trust the reader to draw the conclusion.

## Anti-references

*(Inferred — these are the failure modes this project is most likely to drift into.)*

- **SaaS startup gloss.** Gradient hero, floating product screenshot on a purple-blue wash, vanity metrics, a "Trusted by" logo wall. The default AI landing page, and a lie for a solo open-source tray app.
- **Cutesy edtech.** Mascots, blob illustrations, bubble type, confetti. Talks down to an adult who is simply reading something difficult.
- **Hacker-terminal cosplay.** Black background, neon-green monospace, CLI theatrics. Alienates the non-technical primary audience to flatter the secondary one.
- **Feature-list brochure.** The product has roughly six real behaviors. Padding them into a wall of checkmarks reads as insecurity about having built something small.

## Design Principles

1. **Show the interaction, don't describe it.** "Select a word, see its meaning" must land visually before a single sentence is read. A static explanation of a two-second gesture is a failure of nerve.
2. **Leave no trace — in the product and on the page.** The app stores nothing; the page should ask for nothing. No account, no email capture, no cookie banner, no analytics wall.
3. **Earn trust with specifics, not adjectives.** The ask is "run this unsigned executable that reads your selected text." Answer with concrete facts — HTTPS only, one pinned host, nothing written to disk, source is public, and an honest warning that SmartScreen will complain. Never use the word "secure" as a substitute for saying what happens.
4. **One action, unmistakable.** Downloading is the single conversion. Contributors reach GitHub down the same path; a competing call to action would only split attention.
5. **Restraint is the feature.** This product's best decisions are omissions. The design should omit with the same confidence — and resist adding sections because a page "should" have them.

## Accessibility & Inclusion

*(Inferred from the audience — readers first, some reading in a second language.)*

- **WCAG 2.1 AA.** Body text ≥ 4.5:1 against its background, large text ≥ 3:1. No muted grey body copy on tinted near-white.
- **Reduced motion is required, not optional.** Every animation needs a `prefers-reduced-motion: reduce` alternative that reaches the same end state.
- **Keyboard reachable** with a visible focus style on every interactive element, especially the download buttons.
- **Reading accommodations.** Line height ≥ 1.6, measure capped at 65–75ch, no justified text — this audience includes people reading in a second language and people reading dense material.
- **Never encode meaning in color alone.** Pair any state color with text or shape.
