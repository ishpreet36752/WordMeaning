// Config.swift — central configuration, the macOS counterpart of src/Config.ahk.
// All tunables live here; no magic numbers elsewhere. Values that describe
// behaviour (timeouts, caps, patterns, scoring budgets) are deliberately
// identical to the Windows build, so the two answer the same word the same way.
import Foundation

public enum Config {
    // --- App identity ---
    public static let appName = "WordMeaning"
    public static let bundleIdentifier = "io.github.ishpreet36752.WordMeaning"

    // --- Bundled dictionary (the only source consulted by default) ---
    // ~86k entries generated from WordNet 3.1 by scripts/build-dictionary.ps1.
    // In a built .app it sits in Contents/Resources and is memory-mapped, so the
    // bytes are never copied and nothing is written to disk.
    public static let dictResourceName = "dictionary"
    public static let dictResourceExtension = "dat"

    // --- Optional online fallback (off by default; user turns it on in the menu) ---
    // WordNet is a fixed snapshot and misses newer or rarer words ("selfie").
    // Turning this on trades a network request for that coverage; leaving it off
    // means the program never opens a socket at all.
    public static let onlineFallbackDefault = false
    // HTTPS only; hosts are pinned, word is path-encoded.
    public static let apiBase = "https://freedictionaryapi.com/api/v1/entries/en/"
    // The Wiktionary snapshot behind the primary has gaps of its own, so a miss
    // there is not proof the word is undefined. One call, no key, definitions only.
    public static let apiFallbackBase = "https://api.datamuse.com/words?md=d&max=1&sp="
    public static let onlineMenuText = "Look up missing words online"

    // Attribution for the bundled data and for the optional online sources
    // (shown in the menu bar → About). WordNet requires its notice be reproduced;
    // the primary online source is CC BY-SA 4.0.
    public static let attributionText = """
        Definitions from WordNet 3.1, Princeton University.
        WordNet 3.1 Copyright 2011 by Princeton University.
        All rights reserved. https://wordnet.princeton.edu/

        Optional online lookups (off by default):
        Wiktionary via FreeDictionaryAPI.com, CC BY-SA 4.0
        api.datamuse.com
        """

    // --- Web-search fallback (user-initiated only — never opens the browser by itself) ---
    public static let webSearchUrl = "https://www.google.com/search?q=define+"
    // Command+Shift+D, the Mac spelling of the Windows Ctrl+Shift+D. Registered
    // only while a popup is on screen, so it cannot shadow the same combination
    // in the app being read.
    public static let webSearchKeyCode: UInt32 = 2          // kVK_ANSI_D
    public static let webSearchHint = "\u{2318}\u{21E7}D — search the web"

    // --- Input validation ---
    // Single English word: letters, internal apostrophe/hyphen. Hard length cap.
    public static let wordPattern = "^[A-Za-z][A-Za-z'\\-]{0,31}$"
    public static let maxWordLen = 32

    // --- Selection detection ---
    public static let dragThresholdPx: CGFloat = 5      // min mouse travel to count as drag-selection
    public static let doubleClickInterval: TimeInterval = 0.4

    // --- Timing ---
    public static let clipWaitSec: TimeInterval = 0.3   // how long to wait for Cmd+C to fill the pasteboard
    public static let doubleClickSettleSec: TimeInterval = 0.05
    public static let httpTimeoutSec: TimeInterval = 5
    public static let tooltipTimeoutSec: TimeInterval = 6
    // How often to re-check whether the user has granted Accessibility access.
    public static let permissionPollSec: TimeInterval = 2

    // --- Behavior ---
    public static let maxDefinitionLen = 300    // truncate long definitions in the popup
    public static let maxExampleLen = 140       // truncate the example sentence shown under it
    public static let popupWrapWidth = 58       // wrap popup text to this many chars/line
    public static let cacheMaxEntries = 200     // in-memory lookup cache cap (per session, never persisted)
}
