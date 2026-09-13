import SwiftUI

struct NextIntervalLabel: View {
    let text: String
    let palette: BreakPalette
    @EnvironmentObject private var languageStore: LanguageStore
    @Environment(\.locale) private var locale

    var body: some View {
        Text(languageStore.string("NEXT: \(text)").uppercased(with: locale))
            .font(BreakTypography.label(size: 11, weight: .medium))
            .tracking(0.12)
            .foregroundStyle(palette.inkFaint)
    }
}
