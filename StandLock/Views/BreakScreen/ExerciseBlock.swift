import SwiftUI
import StandLockCore

struct ExerciseBlock: View {
    let exercise: Exercise
    let palette: BreakPalette
    @EnvironmentObject private var languageStore: LanguageStore

    private var titleWithPeriod: String {
        // Resolve first: a Turkish title may end in a period where the English one does not.
        let title = languageStore.string(key: exercise.title)
        return title.hasSuffix(".") ? title : title + "."
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(titleWithPeriod)
                .font(BreakTypography.exerciseName())
                .tracking(-0.5)
                .foregroundStyle(palette.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 560)

            Text(LocalizedStringKey(exercise.description))
                .font(BreakTypography.exerciseBody())
                .foregroundStyle(palette.inkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(17 * 0.6)
                .frame(maxWidth: 560)
        }
    }
}
