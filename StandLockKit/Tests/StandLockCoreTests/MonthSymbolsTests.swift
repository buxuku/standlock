import Foundation
import Testing
@testable import StandLockCore

@Suite("Month symbols")
struct MonthSymbolsTests {
    /// Regression: the symbols used to come from a hardcoded Gregorian calendar while
    /// the month number came from `Calendar.current`, which trapped on every calendar
    /// with a thirteenth month.
    @Test("Every month the calendar can report has a symbol")
    func coversThirteenMonthCalendars() {
        let identifiers: [Calendar.Identifier] = [.gregorian, .hebrew, .coptic, .ethiopicAmeteMihret]
        for identifier in identifiers {
            let calendar = Calendar(identifier: identifier)
            let symbols = shortMonthSymbols(for: calendar, locale: Locale(identifier: "en"))
            let months = calendar.maximumRange(of: .month)?.count ?? 0
            #expect(months > 0)
            #expect(symbols.count >= months, "\(identifier) reports \(months) months but has \(symbols.count) symbols")
        }
    }

    @Test("Names follow the locale, not the system")
    func namesFollowLocale() {
        let gregorian = Calendar(identifier: .gregorian)
        #expect(shortMonthSymbols(for: gregorian, locale: Locale(identifier: "tr")).first == "Oca")
        #expect(shortMonthSymbols(for: gregorian, locale: Locale(identifier: "en")).first == "Jan")
    }
}
