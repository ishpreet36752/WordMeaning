MVP Plan — WordMeaning (Windows, PC-wide)

  Goal: Select word anywhere (browser, PDF, Word, any app) → definition popup near cursor. No pronunciation.
  Auto-trigger, no hotkey.

  Stack

  - AutoHotkey v2 script, single file. No install/build tooling needed beyond AHK runtime.
  - Free API: dictionaryapi.dev (no key, no cost).
  - Popup: AHK ToolTip at cursor coords.

  Core logic

  1. Global mouse hook — detect selection event: left-drag-release OR double-click (word select).
  2. Save current clipboard (restore later, avoid clobbering user's copy).
  3. Simulate Ctrl+C → read new clipboard.
  4. Diff check: new clipboard ≠ old clipboard → real selection happened.
  5. Filter: single word only (regex ^[A-Za-z'-]+$). Multi-word/sentence → skip (MVP scope = words only).
  6. HTTP GET via WinHttp.WinHttpRequest.5.1 COM → api.dictionaryapi.dev/api/v2/entries/en/<word>.
  7. Parse JSON (lightweight regex extract, no full parser needed) → first partOfSpeech + first definition. Skip
  phonetic/audio fields entirely (your "no pronunciation" requirement).
  8. ToolTip shows word + meaning at MouseGetPos location.
  9. Auto-hide after ~4s or on next click/selection.
  10. Restore original clipboard.

  Edge cases (handled, MVP-level)

  - No internet → tiny "offline" tooltip, no crash.
  - Word not found → "no definition found".
  - Selection inside password/secure field → Ctrl+C returns nothing, silently skip.
  - Scanned/image-only PDF (no text layer) → can't select text at all — out of scope, needs OCR (not MVP).
  - Non-English word → API 404 → "no definition found".

  Not in MVP (future)

  - On/off toggle hotkey + tray icon.
  - Auto-start with Windows (startup folder / Task Scheduler).
  - Offline dictionary fallback.
  - Idiom/multi-word phrase lookup.
  - Popup theming (dark/light).
  - Result caching.

  Blocker

  Needs AutoHotkey v2 runtime installed (not present on this PC). Winget install ready, was interrupted — need your
  go-ahead to run it.

  5. Filter: single word only (regex ^[A-Za-z'-]+$). Multi-word/sentence → skip (MVP scope = words only).
  6. HTTP GET via WinHttp.WinHttpRequest.5.1 COM → api.dictionaryapi.dev/api/v2/entries/en/<word>.
  7. Parse JSON (lightweight regex extract, no full parser needed) → first partOfSpeech + first definition. Skip
  phonetic/audio fields entirely (your "no pronunciation" requirement).
  8. ToolTip shows word + meaning at MouseGetPos location.
  9. Auto-hide after ~4s or on next click/selection.
  10. Restore original clipboard.

  Edge cases (handled, MVP-level)

  - No internet → tiny "offline" tooltip, no crash.
  - Word not found → "no definition found".
  - Selection inside password/secure field → Ctrl+C returns nothing, silently skip.
  - Scanned/image-only PDF (no text layer) → can't select text at all — out of scope, needs OCR (not MVP).
  - Non-English word → API 404 → "no definition found".

  Not in MVP (future)

  - On/off toggle hotkey + tray icon.
  - Auto-start with Windows (startup folder / Task Scheduler).
  - Offline dictionary fallback.
  - Idiom/multi-word phrase lookup.
  - Popup theming (dark/light).
  - Result caching.

  Blocker

  Needs AutoHotkey v2 runtime installed (not present on this PC). Winget install ready, was interrupted — need your
  go-ahead to run it.

  Test plan

  Chrome (webpage word), Edge/Adobe PDF (text-layer PDF), Word doc — select word each, confirm popup shows meaning only
  (no pronunciation), confirm original clipboard unchanged after.

  Confirm plan → I install AHK, write script, test all three apps.