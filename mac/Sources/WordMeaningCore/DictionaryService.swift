// DictionaryService.swift — sense selection and lookup routing.
// Port of src/Dictionary.ahk. Named "Service" because `Dictionary` is a Swift type.
//
// Every lookup is answered from the bundled offline dictionary (LocalDictionary).
// Only if the user has switched the online fallback on does a missing word reach
// the network: freedictionaryapi.com (Wiktionary data, no API key) with a Datamuse
// fallback for words that snapshot is missing.
//
// Both online sources list senses in historical order, so the first one is often
// the least useful ("juxtaposition: the nearness of objects with little or no
// delimiter"). score(_:_:_:) picks the most everyday sense instead and carries its
// example sentence; the offline data is built with the same rules applied ahead of
// time. Input validation, HTTPS only, session cache. Pronunciation fields are
// ignored by design.
import Foundation

public struct LookupResult: Equatable {
    public let ok: Bool
    public let word: String
    public let partOfSpeech: String
    public let definition: String
    public let altDefinition: String
    public let example: String
    public let error: String
}

/// Injectable so the tests can exercise the parsers without a network.
public protocol HTTPFetching {
    /// Returns the response body and its status; status 0 means the host could
    /// not be reached at all.
    func get(_ url: String) -> (status: Int, body: String)
}

public final class URLSessionFetcher: HTTPFetching {
    public init() {}

    public func get(_ url: String) -> (status: Int, body: String) {
        guard let u = URL(string: url), u.scheme == "https" else { return (0, "") }
        var request = URLRequest(url: u)
        request.timeoutInterval = Config.httpTimeoutSec
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("\(Config.appName)/1.0", forHTTPHeaderField: "User-Agent")

        // Callers run this off the main thread; blocking here keeps the port
        // shaped like the Windows one, where the request is synchronous too.
        let semaphore = DispatchSemaphore(value: 0)
        var status = 0
        var body = ""
        let task = URLSession.shared.dataTask(with: request) { data, response, _ in
            if let http = response as? HTTPURLResponse { status = http.statusCode }
            if let data { body = String(decoding: data, as: UTF8.self) }
            semaphore.signal()
        }
        task.resume()
        if semaphore.wait(timeout: .now() + Config.httpTimeoutSec + 1) == .timedOut {
            task.cancel()
            return (0, "")
        }
        return (status, body)
    }
}

public final class DictionaryService {
    public static let shared = DictionaryService()

    private let local: LocalDictionary
    private let http: HTTPFetching
    private let lock = NSLock()
    private var cache: [String: LookupResult] = [:]

    /// User-controlled (menu bar). Off by default: a dictionary that ships its own
    /// data has no reason to make requests, and the default should not be the one
    /// that talks to servers. Session-only — never written to disk.
    private var _onlineFallback = Config.onlineFallbackDefault
    public var onlineFallback: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _onlineFallback }
        set { lock.lock(); _onlineFallback = newValue; lock.unlock() }
    }

    public init(local: LocalDictionary = .shared, http: HTTPFetching = URLSessionFetcher()) {
        self.local = local
        self.http = http
    }

    public var isDictionaryAvailable: Bool { local.isAvailable }

    public func lookup(_ rawWord: String) -> LookupResult {
        let word = rawWord.trimmingCharacters(in: .whitespacesAndNewlines)

        if word.count > Config.maxWordLen || !DictionaryService.isSingleWord(word) {
            return DictionaryService.fail(word, "not a single word")
        }

        let key = word.lowercased()
        lock.lock()
        let cached = cache[key]
        lock.unlock()
        if let cached { return cached }

        let result = resolve(key)

        lock.lock()
        if cache.count >= Config.cacheMaxEntries { cache.removeAll() }
        cache[key] = result
        lock.unlock()
        return result
    }

    /// Toggling the online fallback has to drop the cache: words that failed while
    /// offline-only would otherwise stay failed for the rest of the session.
    public func clearCache() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }

    public static func isSingleWord(_ s: String) -> Bool {
        RX.wordPattern.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil
    }

    /// Offline first, always. The network is consulted only for what the bundled
    /// data does not have, and only with the user's say-so.
    private func resolve(_ word: String) -> LookupResult {
        if let rec = local.lookup(word) {
            return DictionaryService.result(rec.word, rec.pos, rec.def, rec.alt, rec.example)
        }
        guard onlineFallback else {
            return DictionaryService.fail(word, local.isAvailable
                                          ? "no definition found"
                                          : "dictionary unavailable")
        }
        return fetch(word)
    }

    // MARK: - Online fallback

    func fetch(_ word: String) -> LookupResult {
        let enc = DictionaryService.urlEncode(word)

        let primary = http.get(Config.apiBase + enc)
        if primary.status == 0 {
            return DictionaryService.fail(word, "offline / network error")
        }
        if primary.status == 200 {
            let r = DictionaryService.parse(word, primary.body)
            if r.ok { return r }
        }

        let secondary = http.get(Config.apiFallbackBase + enc)
        if secondary.status == 200 {
            let r = DictionaryService.parseFallback(word, secondary.body)
            if r.ok { return r }
        }

        // A real 404 means the word is unknown; any other status is the service failing.
        if primary.status != 200 && primary.status != 404 {
            return DictionaryService.fail(word, "service error (\(primary.status))")
        }
        return DictionaryService.fail(word, "no definition found")
    }

    // MARK: - Parsers

    /// Walks the response in document order, collecting one candidate per sense.
    /// Targeted scanning beats a full JSON decode here: three fields are needed and
    /// the order already says which example belongs to which sense (a sense's
    /// examples always follow its definition, and subsenses follow their parent).
    /// "quotes" are deliberately not matched — they are long literary citations.
    static func parse(_ word: String, _ body: String) -> LookupResult {
        var candidates: [Candidate] = []
        var pos = ""
        var open = false

        let ns = body as NSString
        RX.token.enumerateMatches(in: body, range: NSRange(location: 0, length: ns.length)) { m, _, _ in
            guard let m else { return }
            if m.range(at: 1).location != NSNotFound {
                // applies to every sense that follows it
                pos = ns.substring(with: m.range(at: 1))
                open = false
            } else if m.range(at: 2).location != NSNotFound {
                let def = clean(unescape(ns.substring(with: m.range(at: 2))))
                // A skipped sense also closes the slot, so its examples cannot be
                // misattached to the previous kept sense.
                open = !isLabel(def)
                if open { candidates.append(Candidate(pos: pos, def: def, example: "")) }
            } else if m.range(at: 3).location != NSNotFound, open, !candidates.isEmpty {
                candidates[candidates.count - 1].example =
                    cleanExample(unescape(ns.substring(with: m.range(at: 3))))
            }
        }
        return choose(word, candidates)
    }

    /// Datamuse: [{"word":"delimiter","defs":["n\tThat which delimits…", …]}]
    /// No examples here, so scoring only weeds out circular and domain-tagged senses.
    static func parseFallback(_ word: String, _ body: String) -> LookupResult {
        let ns = body as NSString
        let whole = NSRange(location: 0, length: ns.length)

        guard let w = RX.dmWord.firstMatch(in: body, range: whole) else {
            return fail(word, "no definition found")
        }
        guard unescape(ns.substring(with: w.range(at: 1))).lowercased() == word.lowercased() else {
            return fail(word, "no definition found")
        }
        guard let d = RX.dmDefs.firstMatch(in: body, range: whole) else {
            return fail(word, "no definition found")
        }

        let defsBlock = ns.substring(with: d.range(at: 1))
        let block = defsBlock as NSString
        var candidates: [Candidate] = []
        RX.quoted.enumerateMatches(in: defsBlock,
                                   range: NSRange(location: 0, length: block.length)) { m, _, _ in
            guard let m else { return }
            let raw = block.substring(with: m.range(at: 1))
            // Split on the raw two-character \t escape — unescape would flatten it.
            let parts = raw.components(separatedBy: "\\t")
            let def = clean(unescape(parts.count > 1 ? parts[1] : raw))
            if !def.isEmpty && !isLabel(def) {
                candidates.append(Candidate(pos: parts.count > 1 ? posName(parts[0]) : "",
                                            def: def, example: ""))
            }
        }
        return choose(word, candidates)
    }

    // MARK: - Sense selection

    struct Candidate {
        var pos: String
        var def: String
        var example: String
    }

    /// Shows the source's own first sense AND the highest-scoring one. Neither alone
    /// is safe: the first sense is often archaic ("juxtaposition: the nearness of
    /// objects with little or no delimiter") while the best-scoring one can be a deep
    /// subsense ("run: to fuse, to shape, to mould"). Together the reader always gets
    /// a usable reading. Candidates are limited to the first part of speech so one
    /// popup does not mix a noun and a verb under a single header.
    static func choose(_ word: String, _ candidates: [Candidate]) -> LookupResult {
        guard let primary = candidates.first else {
            return fail(word, "no definition found")
        }

        var best = primary
        var bestScore = score(word, primary.def, primary.example)
        for (i, c) in candidates.enumerated() {
            if i == 0 || c.pos != primary.pos { continue }
            let s = score(word, c.def, c.example)
            if s > bestScore {
                bestScore = s
                best = c
            }
        }

        let alt = best.def == primary.def ? "" : best.def
        let example = best.example.isEmpty ? primary.example : best.example
        return result(word, primary.pos, primary.def, alt, example)
    }

    /// Higher is more useful to a human reading a popup:
    ///   +2  has a usable example sentence — the strongest signal of an everyday sense
    ///   -3  circular AND unillustrated ("To place in juxtaposition.") — teaches nothing
    ///   -1  domain-tagged ("(rhetoric) …") — a specialist reading of the word
    ///   -4  a pointer to another entry ("Abbreviation of catapult.") — not a meaning
    static func score(_ word: String, _ def: String, _ example: String) -> Int {
        var s = 0
        if !example.isEmpty {
            s += 2
        } else if def.localizedCaseInsensitiveContains(stem(word)) {
            s -= 3
        }
        if def.range(of: "^\\s*\\(", options: .regularExpression) != nil { s -= 1 }
        if RX.pointer.firstMatch(in: def, range: NSRange(def.startIndex..., in: def)) != nil { s -= 4 }
        return s
    }

    /// Wiktionary files literary citations and bare word-fragments alongside plain
    /// usage sentences. Both are worse than no example at all in a small popup, so
    /// they are dropped rather than truncated — and a sense loses its example bonus
    /// with them.
    static func cleanExample(_ raw: String) -> String {
        var s = raw.replacingOccurrences(of: "\n", with: " ")
        s = s.replacingOccurrences(of: "^\\s*Example:\\s*", with: "", options: .regularExpression)
        s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.range(of: "^\\d{4}", options: .regularExpression) != nil    // "1821-1822, Vicesimus Knox, …"
            || s.contains("ISBN") || s.contains(", page ") || s.contains(", editors,")
            || s.count > Config.maxExampleLen {
            return ""
        }
        let collapsed = s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        if collapsed.split(separator: " ").count < 4 { return "" }       // "to run bullets"
        return s
    }

    /// Strips leading grammatical/register tags — "(countable) A mammal…" reads better
    /// as "A mammal…" and the tag is noise to someone who just wants the meaning.
    /// Subject tags like "(computing)" are kept: they are information, and score(_:)
    /// uses what is left to spot senses that only apply inside one field.
    static func clean(_ definition: String) -> String {
        let grammatical: Set<String> = [
            "countable", "uncountable", "transitive", "intransitive", "ambitransitive",
            "reflexive", "figurative", "by extension", "attributive", "plural", "singular",
            "idiomatic", "informal", "colloquial"
        ]
        var def = definition.trimmingCharacters(in: .whitespacesAndNewlines)
        while true {
            let ns = def as NSString
            guard let m = RX.leadingTag.firstMatch(in: def,
                                                   range: NSRange(location: 0, length: ns.length)) else {
                return def
            }
            let tags = ns.substring(with: m.range(at: 1)).components(separatedBy: ",")
            for tag in tags {
                let t = tag.trimmingCharacters(in: .whitespaces).lowercased()
                if !grammatical.contains(t) { return def }
            }
            def = ns.substring(with: m.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Wiktionary groups senses under headings that are not definitions at all
    /// ("cat: Terms relating to animals."); the real meanings sit in their subsenses.
    static func isLabel(_ def: String) -> Bool {
        let range = NSRange(def.startIndex..., in: def)
        if RX.termsRelating.firstMatch(in: def, range: range) != nil { return true }
        return def.range(of: ":\\s*$", options: .regularExpression) != nil
    }

    /// Crude stem so "delimits"/"juxtapositions" still count as circular.
    static func stem(_ word: String) -> String {
        let w = word.lowercased()
        return w.count > 6 ? String(w.dropLast(3)) : w
    }

    static func posName(_ code: String) -> String {
        switch code {
        case "n": return "noun"
        case "v": return "verb"
        case "adj": return "adjective"
        case "adv": return "adverb"
        case "u": return ""
        default: return code
        }
    }

    /// maxDefinitionLen is the budget for the definitions as a whole — the second
    /// sense is dropped rather than shrunk when it does not fit.
    static func result(_ word: String, _ pos: String, _ definition: String,
                       _ alternative: String, _ example: String) -> LookupResult {
        var def = definition
        var alt = alternative
        if def.count > Config.maxDefinitionLen {
            def = String(def.prefix(Config.maxDefinitionLen)) + "…"
        }
        if def.count + alt.count > Config.maxDefinitionLen { alt = "" }
        return LookupResult(ok: true, word: word, partOfSpeech: pos, definition: def,
                            altDefinition: alt, example: example, error: "")
    }

    static func fail(_ word: String, _ error: String) -> LookupResult {
        LookupResult(ok: false, word: word, partOfSpeech: "", definition: "",
                     altDefinition: "", example: "", error: error)
    }

    static func unescape(_ s: String) -> String {
        var out = s.replacingOccurrences(of: "\\\"", with: "\"")
        out = out.replacingOccurrences(of: "\\/", with: "/")
        out = out.replacingOccurrences(of: "\\n", with: " ")
        out = out.replacingOccurrences(of: "\\t", with: " ")
        out = out.replacingOccurrences(of: "\\\\", with: "\\")
        return out
    }

    /// Public so callers can build the web-search URL without a second encoder.
    public static func urlEncode(_ s: String) -> String {
        var out = ""
        for byte in Array(s.utf8) {
            let c = Character(UnicodeScalar(byte))
            if (c >= "A" && c <= "Z") || (c >= "a" && c <= "z") || (c >= "0" && c <= "9")
                || c == "-" || c == "_" || c == "." || c == "~" {
                out.append(c)
            } else {
                out += String(format: "%%%02X", byte)
            }
        }
        return out
    }
}

/// Compiled once. The patterns are constants, so a failure here is a programming
/// error rather than something to handle at runtime.
enum RX {
    static let wordPattern = make(Config.wordPattern)

    static let token = make(
        #""partOfSpeech"\s*:\s*"([^"]*)""# + "|" +
        #""definition"\s*:\s*"((?:[^"\\]|\\.)*)""# + "|" +
        #""examples"\s*:\s*\[\s*"((?:[^"\\]|\\.)*)""#
    )
    static let dmWord = make(#""word"\s*:\s*"((?:[^"\\]|\\.)*)""#)
    static let dmDefs = make(#""defs"\s*:\s*\[(.*?)\]"#)
    static let quoted = make(#""((?:[^"\\]|\\.)*)""#)

    static let pointer = make(
        #"^\s*(\([^)]*\)\s*)?(abbreviation|acronym|initialism|synonym"# +
        #"|alternative (form|spelling)|obsolete form|misspelling"# +
        #"|plural|singular|past tense|past participle|present participle) of\b"#,
        [.caseInsensitive])
    static let termsRelating = make(#"^\s*(\([^)]*\)\s*)?terms relating to\b"#, [.caseInsensitive])
    static let leadingTag = make(#"^\(([^()]*)\)\s*(.+)$"#)

    private static func make(_ pattern: String,
                             _ options: NSRegularExpression.Options = []) -> NSRegularExpression {
        guard let rx = try? NSRegularExpression(pattern: pattern, options: options) else {
            preconditionFailure("bad regular expression: \(pattern)")
        }
        return rx
    }
}
