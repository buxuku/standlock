import Testing
@testable import StandLockCore

@Suite("Menu Bar Actions")
struct MenuBarActionsTests {
    @Test func nothingThatLoosensEnforcementIsOfferedByDefault() {
        let actions = MenuBarActions(isPaused: false, revealed: false)
        #expect(!actions.skipNextBreak)
        #expect(!actions.pause)
        #expect(!actions.settings)
        #expect(!actions.resume)
    }

    @Test func revealingOffersSkipPauseAndSettings() {
        let actions = MenuBarActions(isPaused: false, revealed: true)
        #expect(actions.skipNextBreak)
        #expect(actions.pause)
        #expect(actions.settings)
        #expect(!actions.resume)
    }

    @Test func resumeIsOfferedWhilePausedEvenWhenNotRevealed() {
        let actions = MenuBarActions(isPaused: true, revealed: false)
        #expect(actions.resume)
        #expect(!actions.skipNextBreak)
        #expect(!actions.pause)
        #expect(!actions.settings)
    }

    @Test func pausedAndRevealedOffersResumeAndSettingsButNotSkipOrPause() {
        let actions = MenuBarActions(isPaused: true, revealed: true)
        #expect(actions.resume)
        #expect(!actions.skipNextBreak)
        #expect(!actions.pause)
        #expect(actions.settings)
    }
}
