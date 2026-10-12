import Foundation

/// Decides when the emergency escape combination has been held long enough.
///
/// The combination is Control, Option, Command, Shift and P held together, and nothing else.
/// Any other key down at the same moment, whether it went down before the combination or while
/// it was held, means the combination is not being held, so pressing every key at once never
/// counts. Caps Lock is a lock rather than a held key, so it is not part of this.
public struct EscapeDetector: Sendable {
    /// The modifier keys currently down.
    public struct Modifiers: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let control = Modifiers(rawValue: 1 << 0)
        public static let option = Modifiers(rawValue: 1 << 1)
        public static let command = Modifiers(rawValue: 1 << 2)
        public static let shift = Modifiers(rawValue: 1 << 3)
        /// Fn, or Globe. It is a key like any other, so it is not part of the combination.
        public static let function = Modifiers(rawValue: 1 << 4)
    }

    /// The modifiers of the combination. Any other modifier down at the same time breaks it.
    public static let requiredModifiers: Modifiers = [.control, .option, .command, .shift]

    /// Virtual key code of the letter in the combination (`kVK_ANSI_P`).
    public static let comboKeyCode: Int64 = 35

    public let requiredDuration: TimeInterval
    public private(set) var holdStartTime: Date?
    public private(set) var isHolding: Bool = false
    public private(set) var modifiers: Modifiers = []
    public private(set) var isComboKeyDown: Bool = false
    /// Keys other than the combination's letter that are down, by virtual key code.
    public private(set) var otherKeysDown: Set<Int64> = []

    public init(requiredDuration: TimeInterval = 10.0) {
        self.requiredDuration = requiredDuration
    }

    /// The modifier keys changed. `modifiers` is every modifier down now, not just what changed.
    public mutating func flagsChanged(_ modifiers: Modifiers, at time: Date) {
        self.modifiers = modifiers
        updateHolding(at: time)
    }

    public mutating func keyChanged(keyCode: Int64, isDown: Bool, at time: Date) {
        if keyCode == Self.comboKeyCode {
            isComboKeyDown = isDown
        } else if isDown {
            otherKeysDown.insert(keyCode)
        } else {
            otherKeysDown.remove(keyCode)
        }
        updateHolding(at: time)
    }

    private mutating func updateHolding(at time: Date) {
        let exactlyTheCombination = modifiers == Self.requiredModifiers
            && isComboKeyDown
            && otherKeysDown.isEmpty
        if exactlyTheCombination && !isHolding {
            holdStartTime = time
            isHolding = true
        } else if !exactlyTheCombination {
            holdStartTime = nil
            isHolding = false
        }
    }

    public func isEscapeTriggered(at currentTime: Date) -> Bool {
        guard let start = holdStartTime else { return false }
        return currentTime.timeIntervalSince(start) >= requiredDuration
    }

    public mutating func reset() {
        holdStartTime = nil
        isHolding = false
        modifiers = []
        isComboKeyDown = false
        otherKeysDown = []
    }
}
