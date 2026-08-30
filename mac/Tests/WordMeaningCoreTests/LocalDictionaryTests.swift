// LocalDictionaryTests.swift — the bundled dictionary on macOS: binary search
// across the whole file, record shape, frequency-chosen part of speech,
// irregular and regular inflections, headword-beats-stripping, clean misses.
// The macOS mirror of tests/DictTest.ahk. No network.
//
// Needs assets/dictionary.dat: build it with scripts/build-dictionary.ps1 (pwsh
// runs it on macOS too). Without the file every test here would report a
// confusing miss, so the suite fails loudly on the first check instead.
import XCTest
@testable import WordMeaningCore

final class LocalDictionaryTests: XCTestCase {
    private var service: DictionaryService!

    override func setUpWithError() throws {
        guard LocalDictionary.locateData() != nil else {
            XCTFail("dictionary not found — run scripts/build-dictionary.ps1 first")
            return
        }
        // Offline only: no fetcher is supplied that could reach a network.
        service = DictionaryService(local: LocalDictionary(), http: FailingFetcher())
    }

    func testDictionaryLoads() {
        XCTAssertTrue(LocalDictionary().isAvailable)
    }

    /// Deliberately spread across the alphabet: a search that only works near the
    /// middle of the file would still pass a single-word test.
    func testFindsEntriesAcrossTheFile() {
        for word in ["aardvark", "cat", "dog", "ephemeral", "juxtaposition",
                     "meaning", "serendipity", "obfuscate", "quixotic", "zygote"] {
            let r = service.lookup(word)
            XCTAssertTrue(r.ok, "missed '\(word)'")
            XCTAssertFalse(r.definition.isEmpty, "empty definition for '\(word)'")
        }
    }

    /// First and last records specifically: an off-by-one in the search bounds
    /// shows up at the ends, not in the middle.
    func testFindsFirstAndLastRecords() {
        let first = service.lookup("a")
        XCTAssertTrue(first.ok)
        XCTAssertFalse(first.definition.isEmpty)

        let last = service.lookup("zyrian")
        XCTAssertTrue(last.ok)
        XCTAssertFalse(last.definition.isEmpty)
    }

    func testRecordsAreWellFormed() {
        let dog = service.lookup("dog")
        XCTAssertEqual(dog.partOfSpeech, "noun")
        XCTAssertTrue(dog.example.localizedCaseInsensitiveContains("dog"))
        XCTAssertFalse(dog.definition.hasPrefix("#"), "read a comment line as a record")

        let cat = service.lookup("cat")
        XCTAssertTrue(cat.ok)
        XCTAssertFalse(cat.altDefinition.isEmpty, "second sense missing where one exists")
    }

    /// "better" has more verb senses than adjective ones, but the tagged corpora
    /// put the adjective ahead 92 to 3.
    func testFrequencyChoosesPartOfSpeech() {
        XCTAssertEqual(service.lookup("better").partOfSpeech, "adjective")
    }

    func testIrregularInflections() {
        XCTAssertEqual(service.lookup("ran").word, "run")
        XCTAssertEqual(service.lookup("mice").word, "mouse")
    }

    func testRegularInflections() {
        XCTAssertEqual(service.lookup("dogs").word, "dog")
        XCTAssertEqual(service.lookup("ponies").word, "pony")
        XCTAssertEqual(service.lookup("walked").word, "walk")
        XCTAssertTrue(service.lookup("running").ok)
    }

    /// A word that is itself a headword must not be mangled into another one:
    /// "as" must not become "a".
    func testHeadwordBeatsSuffixStripping() {
        let r = service.lookup("as")
        XCTAssertTrue(r.ok)
        XCTAssertEqual(r.word, "as")
    }

    /// A word WordNet has no entry for can still be answered through its root.
    /// The popup header shows what was resolved to, so nothing is misattributed.
    func testResolvesThroughRoot() {
        XCTAssertEqual(service.lookup("delimiter").word, "delimit")
    }

    func testMissesAreClean() {
        XCTAssertFalse(service.onlineFallback, "the online fallback must be off by default")
        let miss = service.lookup("qzxqzxqzx")
        XCTAssertFalse(miss.ok)
        XCTAssertEqual(miss.error, "no definition found")
    }

    func testValidationGatesTheLookup() {
        let multi = service.lookup("two words")
        XCTAssertFalse(multi.ok)
        XCTAssertEqual(multi.error, "not a single word")

        let junk = service.lookup("a1b2!")
        XCTAssertFalse(junk.ok)
        XCTAssertEqual(junk.error, "not a single word")
    }

    func testCacheIsConsistentWithinASession() {
        XCTAssertEqual(service.lookup("dog").definition, service.lookup("dog").definition)
    }
}

/// Any attempt to reach the network during the offline suite is a test failure,
/// not a slow test.
private struct FailingFetcher: HTTPFetching {
    func get(_ url: String) -> (status: Int, body: String) {
        XCTFail("offline tests must not make a request (\(url))")
        return (0, "")
    }
}
