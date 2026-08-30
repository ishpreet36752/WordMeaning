// PopupText.swift — turns a LookupResult into the exact text the popup shows.
// This is Main.OnSelection's formatting from the Windows build, lifted out so it
// is testable and so both platforms cannot drift apart in how a result reads.
import Foundation

public enum PopupText {
    /// The text for a result, or nil when nothing should be shown at all.
    /// Nil happens for a multi-word or non-word selection: the program stays
    /// completely silent rather than explaining itself, exactly as on Windows.
    public static func compose(_ result: LookupResult) -> String? {
        if result.ok {
            let header = result.word
                + (result.partOfSpeech.isEmpty ? "" : " (\(result.partOfSpeech))")
            // Two senses are numbered; a lone sense is not, so the common case stays terse.
            var body = result.altDefinition.isEmpty
                ? result.definition
                : "1. \(result.definition)\n2. \(result.altDefinition)"
            if !result.example.isEmpty {
                body += "\n\"\(result.example)\""
            }
            return header + "\n" + body
        }

        if result.error == "not a single word" { return nil }

        // Dead end — offer the browser. Never open it unasked: that would steal
        // focus and hand the word to a search engine the user did not choose.
        return "\(result.word)\n\(result.error)\n\(Config.webSearchHint)"
    }
}
