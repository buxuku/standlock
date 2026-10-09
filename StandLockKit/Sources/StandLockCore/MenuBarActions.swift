/// Which quick actions the menu bar panel offers.
///
/// Skipping or pausing a break, and opening Settings (where a schedule can be switched off or
/// moved down from Strict), all loosen enforcement. They are offered only while `revealed`.
/// Resuming a paused schedule tightens enforcement again, so it is always offered.
public struct MenuBarActions: Equatable, Sendable {
    public let resume: Bool
    public let skipNextBreak: Bool
    public let pause: Bool
    /// Settings and About open the same window, so they share one flag.
    public let settings: Bool

    public init(isPaused: Bool, revealed: Bool) {
        resume = isPaused
        skipNextBreak = revealed && !isPaused
        pause = revealed && !isPaused
        settings = revealed
    }
}
