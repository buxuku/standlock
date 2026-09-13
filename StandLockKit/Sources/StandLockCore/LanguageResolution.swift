import Foundation

/// Picks the language the app should render in.
///
/// - Parameters:
///   - selection: The user's explicit choice, or `nil` to follow the system.
///   - available: Language codes the app ships, e.g. `["en", "tr"]`.
///   - systemPreferred: The system language list, newest first. Entries may carry
///     a region tag (`"tr-TR"`); only the part before the first separator is matched.
/// - Returns: A member of `available`, or `"en"` when nothing matches.
public func resolveLanguage(
    selection: String?,
    available: [String],
    systemPreferred: [String]
) -> String {
    if let selection, let match = matchingEntry(for: selection, in: available) {
        return match
    }
    for candidate in systemPreferred {
        if let match = matchingEntry(for: candidate, in: available) {
            return match
        }
    }
    return "en"
}

private func matchingEntry(for candidate: String, in available: [String]) -> String? {
    let wanted = languageCode(of: candidate)
    guard !wanted.isEmpty else { return nil }
    return available.first { languageCode(of: $0) == wanted }
}

private func languageCode(of identifier: String) -> String {
    let base = identifier.prefix { $0 != "-" && $0 != "_" }
    return base.lowercased()
}
