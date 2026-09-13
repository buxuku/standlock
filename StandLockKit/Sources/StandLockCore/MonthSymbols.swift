import Foundation

/// Month abbreviations for `calendar`, named in `locale`.
///
/// The symbols have to come from the same calendar that produced the month
/// number they are indexed with. Coptic and Ethiopic run thirteen months every
/// year and Hebrew runs thirteen in a leap year, so a Gregorian array of twelve
/// is indexed past its end and traps.
public func shortMonthSymbols(for calendar: Calendar, locale: Locale) -> [String] {
    var named = calendar
    named.locale = locale
    return named.shortMonthSymbols
}
