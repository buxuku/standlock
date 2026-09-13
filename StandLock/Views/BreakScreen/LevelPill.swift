import SwiftUI
import StandLockCore

struct LevelPill: View {
    let level: DisciplineLevel
    let palette: BreakPalette
    @EnvironmentObject private var languageStore: LanguageStore
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(palette.accent)
                .frame(width: 6, height: 6)
            Text(languageStore.string(key: level.displayName).uppercased(with: locale))
                .font(BreakTypography.label(size: 11, weight: .semibold))
                .tracking(3.08)
                .foregroundStyle(palette.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(palette.accent.opacity(0.15))
        )
        .overlay(
            Capsule()
                .strokeBorder(palette.accent, lineWidth: 1)
        )
    }
}
