import Foundation
import Testing
@testable import StandLockCore

@Suite("Phrase Matching")
struct PhraseMatchingTests {

    let tr = Locale(identifier: "tr")
    let en = Locale(identifier: "en")

    @Test func turkishUppercasePhraseMatches() {
        #expect(phraseMatches(
            "BU MOLAYI ATLAMAYI SEÇİYORUM",
            expected: "Bu molayı atlamayı seçiyorum",
            locale: tr
        ))
    }

    @Test func turkishDottedAndDotlessArePairedCorrectly() {
        #expect(phraseMatches("ı", expected: "I", locale: tr))
        #expect(phraseMatches("i", expected: "İ", locale: tr))
    }

    @Test func turkishPlainIAndCapitalIAreNotAPair() {
        #expect(!phraseMatches("i", expected: "I", locale: tr))
    }

    @Test func englishLocaleDoesNotPairDotlessI() {
        #expect(!phraseMatches("ı", expected: "I", locale: en))
    }

    @Test func diacriticsNeverFold() {
        #expect(!phraseMatches("seciyorum", expected: "seçiyorum", locale: tr))
    }

    @Test func surroundingWhitespaceIsTrimmed() {
        #expect(phraseMatches(
            "  I choose to skip this break ",
            expected: "I choose to skip this break",
            locale: en
        ))
    }

    @Test func partialInputDoesNotMatch() {
        #expect(!phraseMatches("i choose to skip", expected: "I choose to skip this break", locale: en))
    }

    /// Regression evidence: the locale-free comparison this matcher replaces fails
    /// on a Turkish phrase, which is why `phraseMatches` exists.
    @Test func caseInsensitiveCompareFailsOnTurkish() {
        #expect("BU MOLAYI ATLAMAYI SEÇİYORUM"
            .caseInsensitiveCompare("Bu molayı atlamayı seçiyorum") != .orderedSame)
    }
}
