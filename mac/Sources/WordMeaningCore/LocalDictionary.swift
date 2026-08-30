// LocalDictionary.swift — the bundled offline dictionary (WordNet 3.1).
// Port of src/LocalDictionary.ahk, byte-for-byte compatible with the same
// assets/dictionary.dat: one tab-separated record per line, sorted ordinally.
//
// The file is never parsed into a dictionary in memory — 86k entries would cost
// far more RAM than a menu bar app should take. It is memory-mapped and the
// sorted bytes are binary-searched in place, so a lookup touches a handful of
// pages and the resident cost is paid by the page cache, not by us. Mapping is
// also why the built .app writes nothing to disk to answer a word.
import Foundation

public struct DictionaryEntry: Equatable {
    public let word: String
    public let pos: String
    public let def: String
    public let alt: String
    public let example: String

    public init(word: String, pos: String, def: String, alt: String, example: String) {
        self.word = word
        self.pos = pos
        self.def = def
        self.alt = alt
        self.example = example
    }
}

public final class LocalDictionary {
    public static let shared = LocalDictionary()

    private var data: Data?
    private var tried = false
    private let lock = NSLock()

    /// Morphy's suffix-detachment rules. Irregular forms ("ran", "mice") are
    /// redirect records in the data file; these rules cover the regular ones for
    /// free, which is why the file does not carry millions of inflections.
    /// Longest suffixes first: "ponies" must hit "ies"->"y" before "s"->"".
    private static let rules: [(suffix: String, replacement: String)] = [
        ("ches", "ch"), ("shes", "sh"), ("ses", "s"), ("xes", "x"),
        ("zes", "z"), ("ies", "y"), ("men", "man"), ("ing", ""),
        ("ing", "e"), ("est", ""), ("est", "e"), ("ed", ""),
        ("ed", "e"), ("es", ""), ("es", "e"), ("er", ""),
        ("er", "e"), ("s", "")
    ]

    public init() {}

    /// Tests (and anything that wants a specific corpus) hand the bytes straight in.
    public init(data: Data) {
        self.data = data
        self.tried = true
    }

    /// True once the data is available. A build with no dictionary still runs —
    /// it just has nothing to answer with until the online fallback is enabled.
    public var isAvailable: Bool {
        loadIfNeeded()
        lock.lock()
        defer { lock.unlock() }
        return (data?.count ?? 0) > 0
    }

    /// Returns the entry for a hit, or nil for a miss. `word` on the result is the
    /// entry actually found, which for an inflected form is the base word
    /// ("ran" resolves to, and is shown as, "run").
    public func lookup(_ word: String) -> DictionaryEntry? {
        guard isAvailable else { return nil }
        lock.lock()
        let bytes = data
        lock.unlock()
        guard let bytes, !bytes.isEmpty else { return nil }

        let key = word.lowercased()
        return bytes.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> DictionaryEntry? in
            if let hit = entry(for: key, in: raw) { return hit }

            // Not a headword — try to strip a regular inflection.
            for rule in LocalDictionary.rules {
                guard key.count > rule.suffix.count, key.hasSuffix(rule.suffix) else { continue }
                let candidate = String(key.dropLast(rule.suffix.count)) + rule.replacement
                if candidate.count < 2 { continue }
                if let hit = entry(for: candidate, in: raw) { return hit }
            }
            return nil
        }
    }

    // MARK: - Loading

    private func loadIfNeeded() {
        lock.lock()
        defer { lock.unlock() }
        guard !tried else { return }
        tried = true
        guard let url = LocalDictionary.locateData() else { return }
        // .mappedIfSafe: the file is faulted in page by page instead of copied.
        data = try? Data(contentsOf: url, options: .mappedIfSafe)
    }

    /// Where the packed dictionary lives, in the order it is looked for.
    /// A built .app always finds it in its own Resources; the other two paths
    /// exist so `swift run` and `swift test` work from a checkout, where there
    /// is no bundle at all.
    public static func locateData() -> URL? {
        if let url = Bundle.main.url(forResource: Config.dictResourceName,
                                     withExtension: Config.dictResourceExtension) {
            return url
        }
        if let override = ProcessInfo.processInfo.environment["WORDMEANING_DICT"] {
            let url = URL(fileURLWithPath: override)
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        // repo layout: mac/ is one level under the repository root.
        let name = "\(Config.dictResourceName).\(Config.dictResourceExtension)"
        var candidates: [URL] = []
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        candidates.append(cwd.appendingPathComponent("assets/\(name)"))
        candidates.append(cwd.appendingPathComponent("../assets/\(name)"))
        let exeDir = Bundle.main.bundleURL.deletingLastPathComponent()
        candidates.append(exeDir.appendingPathComponent(name))
        candidates.append(exeDir.appendingPathComponent("../../../../assets/\(name)"))
        for url in candidates where FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        return nil
    }

    // MARK: - Search

    private func entry(for key: String, in raw: UnsafeRawBufferPointer) -> DictionaryEntry? {
        guard let line = findLine(Array(key.utf8), in: raw) else { return nil }
        return record(key: key, line: line, in: raw)
    }

    /// Binary search over the byte range. Every line begins a record and the file
    /// is sorted by key, so the usual halving works on byte offsets as long as
    /// each probe is nudged forward to the next line boundary.
    private func findLine(_ key: [UInt8], in raw: UnsafeRawBufferPointer) -> String? {
        let size = raw.count
        guard size > 0 else { return nil }

        var lo = 0
        var hi = size
        while lo < hi {
            let mid = (lo + hi) / 2
            var s = mid
            if s > 0 {                                  // advance to a line start
                while s < size && raw[s] != 0x0A { s += 1 }
                s += 1
            }
            if s >= hi {
                hi = mid
                continue
            }
            if compare(raw, at: s, key: key) < 0 {
                var e = s
                while e < size && raw[e] != 0x0A { e += 1 }
                lo = e + 1                              // whole line ruled out
            } else {
                hi = mid
            }
        }

        // lo is a line start and the answer, if present, is at or just past it.
        // The bound is paranoia: a corrupt file must not spin here.
        var pos = lo
        for _ in 0..<64 {
            if pos >= size { return nil }
            let c = compare(raw, at: pos, key: key)
            var e = pos
            while e < size && raw[e] != 0x0A { e += 1 }
            if c == 0 {
                let slice = UnsafeRawBufferPointer(rebasing: raw[pos..<e])
                return String(decoding: slice, as: UTF8.self)
            }
            if c > 0 { return nil }                     // past where it would be
            pos = e + 1
        }
        return nil
    }

    /// Ordinal comparison of the key at byte offset `at` against the needle.
    /// Ordinal on purpose: it has to agree with the byte order the generator
    /// sorted the file in, which a locale- or case-aware comparison would not.
    private func compare(_ raw: UnsafeRawBufferPointer, at: Int, key: [UInt8]) -> Int {
        var i = 0
        while true {
            let index = at + i
            if index >= raw.count { return i >= key.count ? 0 : -1 }
            let b = raw[index]
            if b == 0x09 || b == 0x0A {                 // tab or newline ends the key
                return i >= key.count ? 0 : -1
            }
            if i >= key.count { return 1 }
            let t = key[i]
            if b != t { return b < t ? -1 : 1 }
            i += 1
        }
    }

    /// "key<TAB>pos<TAB>def<TAB>alt<TAB>example", or a redirect for an irregular
    /// form: "mice<TAB>=<TAB>mouse".
    private func record(key: String, line: String, in raw: UnsafeRawBufferPointer) -> DictionaryEntry? {
        let fields = LocalDictionary.split(line)
        guard fields.count >= 2 else { return nil }

        if fields[1] == "=" {
            // One hop only. The generator never chains redirects, and refusing to
            // follow a second one means a bad file cannot loop us.
            let target = fields.count >= 3 ? fields[2] : ""
            guard !target.isEmpty, target != key else { return nil }
            guard let line2 = findLine(Array(target.utf8), in: raw) else { return nil }
            let f2 = LocalDictionary.split(line2)
            guard f2.count >= 2, f2[1] != "=" else { return nil }
            return LocalDictionary.entry(from: f2)
        }
        return LocalDictionary.entry(from: fields)
    }

    private static func split(_ line: String) -> [String] {
        var text = line
        if text.hasSuffix("\r") { text.removeLast() }
        return text.components(separatedBy: "\t")
    }

    private static func entry(from f: [String]) -> DictionaryEntry {
        DictionaryEntry(word: f[0],
                        pos: f[1],
                        def: f.count >= 3 ? f[2] : "",
                        alt: f.count >= 4 ? f[3] : "",
                        example: f.count >= 5 ? f[4] : "")
    }
}
