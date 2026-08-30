// SenseSelectionTests.swift — the parsers, the scoring, the cleaning, the popup
// text, and the wrapping. Everything here is deterministic and offline: the
// online sources are replaced by a stub that replays a recorded body, which is
// what tests/SmokeTest.ahk needs a real network for on Windows.
import XCTest
@testable import WordMeaningCore

final class SenseSelectionTests: XCTestCase {

    // MARK: - Cleaning

    func testCleanStripsGrammaticalTagsOnly() {
        XCTAssertEqual(DictionaryService.clean("(countable) A mammal."), "A mammal.")
        XCTAssertEqual(DictionaryService.clean("(transitive, informal) To run."), "To run.")
        // Subject tags are information, not noise: they stay.
        XCTAssertEqual(DictionaryService.clean("(computing) A delimiter."), "(computing) A delimiter.")
    }

    func testIsLabelDropsGroupingHeadings() {
        XCTAssertTrue(DictionaryService.isLabel("Terms relating to animals."))
        XCTAssertTrue(DictionaryService.isLabel("Senses relating to the following:"))
        XCTAssertFalse(DictionaryService.isLabel("A small domesticated carnivore."))
    }

    func testCleanExampleRejectsCitationsAndFragments() {
        // A literary citation, not a usage example.
        XCTAssertEqual(DictionaryService.cleanExample("1821-1822, Vicesimus Knox, Winter Evenings"), "")
        XCTAssertEqual(DictionaryService.cleanExample("Smith, J., ISBN 978-0-00-000000-0"), "")
        XCTAssertEqual(DictionaryService.cleanExample("to run bullets"), "")     // under four words
        XCTAssertEqual(DictionaryService.cleanExample(String(repeating: "a", count: 200)), "")
        XCTAssertEqual(DictionaryService.cleanExample("She ran to the station in the rain."),
                       "She ran to the station in the rain.")
        XCTAssertEqual(DictionaryService.cleanExample("Example: He ran the whole way home."),
                       "He ran the whole way home.")
    }

    // MARK: - Scoring

    func testScorePrefersAnIllustratedSense() {
        let withExample = DictionaryService.score("run", "To move quickly on foot.", "She ran home fast.")
        let without = DictionaryService.score("run", "To move quickly on foot.", "")
        XCTAssertGreaterThan(withExample, without)
    }

    func testScorePunishesCircularAndPointerSenses() {
        // Circular and unillustrated teaches nothing.
        XCTAssertLessThan(DictionaryService.score("juxtaposition", "To place in juxtaposition.", ""), 0)
        // A pointer to another entry is not a meaning.
        XCTAssertLessThan(DictionaryService.score("cat", "Abbreviation of catapult.", ""), -3)
        // A domain tag marks a specialist reading.
        XCTAssertLessThan(DictionaryService.score("figure", "(rhetoric) A turn of phrase.", ""), 0)
    }

    // MARK: - Choosing

    func testChooseShowsFirstAndBestSense() {
        let candidates = [
            DictionaryService.Candidate(pos: "noun", def: "The nearness of objects.", example: ""),
            DictionaryService.Candidate(pos: "noun", def: "An act of placing side by side.",
                                        example: "The juxtaposition of old and new was deliberate.")
        ]
        let r = DictionaryService.choose("juxtaposition", candidates)
        XCTAssertTrue(r.ok)
        XCTAssertEqual(r.definition, "The nearness of objects.")            // the source's first
        XCTAssertEqual(r.altDefinition, "An act of placing side by side.")  // the best-scoring
        XCTAssertFalse(r.example.isEmpty)
    }

    func testChooseStaysWithinOnePartOfSpeech() {
        let candidates = [
            DictionaryService.Candidate(pos: "noun", def: "A domesticated carnivore.", example: ""),
            DictionaryService.Candidate(pos: "verb", def: "To hoist an anchor.",
                                        example: "They catted the anchor at dawn.")
        ]
        let r = DictionaryService.choose("cat", candidates)
        XCTAssertEqual(r.partOfSpeech, "noun")
        XCTAssertEqual(r.altDefinition, "", "a verb sense must not be shown under a noun header")
    }

    func testResultDropsTheSecondSenseRatherThanShrinkIt() {
        let long = String(repeating: "x", count: Config.maxDefinitionLen - 10)
        let r = DictionaryService.result("word", "noun", long, "a second sense", "")
        XCTAssertEqual(r.altDefinition, "")
        XCTAssertEqual(r.definition, long)
    }

    // MARK: - Parsers

    func testParsesThePrimarySource() {
        let body = """
        {"word":"ephemeral","entries":[{"partOfSpeech":"adjective","senses":[
        {"definition":"(literary) Lasting a very short time.",
         "examples":["The ephemeral joys of a summer holiday."]}]}]}
        """
        let r = DictionaryService.parse("ephemeral", body)
        XCTAssertTrue(r.ok)
        XCTAssertEqual(r.partOfSpeech, "adjective")
        XCTAssertEqual(r.definition, "(literary) Lasting a very short time.")
        XCTAssertEqual(r.example, "The ephemeral joys of a summer holiday.")
    }

    func testAnExampleIsNeverAttachedToASkippedSense() {
        // The heading is dropped; its example must not land on a later sense.
        let body = """
        {"entries":[{"partOfSpeech":"noun","senses":[
        {"definition":"Terms relating to animals.","examples":["A heading, not a sense."]},
        {"definition":"A small domesticated carnivore."}]}]}
        """
        let r = DictionaryService.parse("cat", body)
        XCTAssertTrue(r.ok)
        XCTAssertEqual(r.definition, "A small domesticated carnivore.")
        XCTAssertEqual(r.example, "")
    }

    func testParsesTheDatamuseFallback() {
        let body = #"[{"word":"delimiter","defs":["n\tThat which delimits a field of data."]}]"#
        let r = DictionaryService.parseFallback("delimiter", body)
        XCTAssertTrue(r.ok)
        XCTAssertEqual(r.partOfSpeech, "noun")
        XCTAssertEqual(r.definition, "That which delimits a field of data.")
    }

    func testDatamuseAnswerForAnotherWordIsRejected() {
        let body = #"[{"word":"delimit","defs":["v\tTo mark the limits of."]}]"#
        XCTAssertFalse(DictionaryService.parseFallback("delimiter", body).ok)
    }

    func testFallbackIsUsedOnlyWhenThePrimaryHasNothing() {
        let stub = StubFetcher(responses: [
            Config.apiBase + "selfie": (200, #"{"word":"selfie","entries":[]}"#),
            Config.apiFallbackBase + "selfie": (200, #"[{"word":"selfie","defs":["n\tA photograph of oneself."]}]"#)
        ])
        let service = DictionaryService(local: LocalDictionary(data: Data()), http: stub)
        service.onlineFallback = true
        let r = service.lookup("selfie")
        XCTAssertTrue(r.ok)
        XCTAssertEqual(r.definition, "A photograph of oneself.")
        XCTAssertEqual(stub.requested.count, 2)
    }

    func testUnreachableHostReportsOffline() {
        let service = DictionaryService(local: LocalDictionary(data: Data()),
                                        http: StubFetcher(responses: [:]))
        service.onlineFallback = true
        XCTAssertEqual(service.lookup("selfie").error, "offline / network error")
    }

    func testNoRequestIsMadeWhileTheFallbackIsOff() {
        let stub = StubFetcher(responses: [:])
        let service = DictionaryService(local: LocalDictionary(data: Data()), http: stub)
        let r = service.lookup("selfie")
        XCTAssertFalse(r.ok)
        XCTAssertTrue(stub.requested.isEmpty, "a socket was opened with the fallback off")
    }

    func testUrlEncodingIsRestrictive() {
        XCTAssertEqual(DictionaryService.urlEncode("cat"), "cat")
        XCTAssertEqual(DictionaryService.urlEncode("mother's"), "mother%27s")
        XCTAssertEqual(DictionaryService.urlEncode("a b"), "a%20b")
    }

    // MARK: - Popup text and wrapping

    func testPopupTextNumbersTwoSensesOnly() {
        let one = DictionaryService.result("cat", "noun", "A carnivore.", "", "")
        XCTAssertEqual(PopupText.compose(one), "cat (noun)\nA carnivore.")

        let two = DictionaryService.result("cat", "noun", "A carnivore.", "A whip.", "")
        XCTAssertEqual(PopupText.compose(two), "cat (noun)\n1. A carnivore.\n2. A whip.")
    }

    func testPopupStaysSilentOnAMultiWordSelection() {
        XCTAssertNil(PopupText.compose(DictionaryService.fail("two words", "not a single word")))
    }

    func testPopupOffersTheWebSearchOnAMiss() {
        let text = PopupText.compose(DictionaryService.fail("qzxqzx", "no definition found"))
        XCTAssertEqual(text, "qzxqzx\nno definition found\n\(Config.webSearchHint)")
    }

    func testWrappingStaysUnderTheWidthAndLosesNothing() {
        let long = "A necessity or prerequisite; something required or obligatory in relation to what is required."
        let wrapped = TextWrap.wrap(long, width: 58)
        let longest = wrapped.components(separatedBy: "\n").map(\.count).max() ?? 0
        XCTAssertLessThanOrEqual(longest, 58)
        XCTAssertTrue(wrapped.contains("\n"))
        XCTAssertEqual(wrapped.replacingOccurrences(of: "\n", with: " "), long)

        XCTAssertEqual(TextWrap.wrap("serendipity (noun)", width: 58), "serendipity (noun)")
        XCTAssertTrue(TextWrap.wrap("word (noun)\nsome definition here", width: 58)
            .hasPrefix("word (noun)\n"))
    }
}

/// Replays recorded bodies and records what was asked for, so "no request is made"
/// is a thing the suite can actually assert.
private final class StubFetcher: HTTPFetching {
    private let responses: [String: (Int, String)]
    private(set) var requested: [String] = []

    init(responses: [String: (Int, String)]) {
        self.responses = responses
    }

    func get(_ url: String) -> (status: Int, body: String) {
        requested.append(url)
        guard let hit = responses[url] else { return (0, "") }
        return (status: hit.0, body: hit.1)
    }
}
