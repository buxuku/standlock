import Foundation

/// Compares typed input against an expected escape phrase.
///
/// Surrounding whitespace is trimmed and the comparison is case-insensitive under
/// `locale`, so Turkish pairs ı/I and i/İ while leaving i/I distinct. Diacritics are
/// never folded: ş and s, ğ and g, ç and c stay different letters.
public func phraseMatches(_ input: String, expected: String, locale: Locale) -> Bool {
    input
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .compare(expected, options: [.caseInsensitive], range: nil, locale: locale) == .orderedSame
}
