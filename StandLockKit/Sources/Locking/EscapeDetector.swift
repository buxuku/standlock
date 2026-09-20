import Foundation

public struct EscapeDetector: Sendable {
    public let requiredDuration: TimeInterval
    public private(set) var holdStartTime: Date?
    public private(set) var isHolding: Bool = false
    public private(set) var isControlDown: Bool = false
    public private(set) var isOptionDown: Bool = false
    public private(set) var isCommandDown: Bool = false
    public private(set) var isKDown: Bool = false

    public init(requiredDuration: TimeInterval = 10.0) {
        self.requiredDuration = requiredDuration
    }

    public mutating func flagsChanged(
        controlDown: Bool, optionDown: Bool,
        commandDown: Bool, at time: Date
    ) {
        isControlDown = controlDown
        isOptionDown = optionDown
        isCommandDown = commandDown
        updateHolding(at: time)
    }

    public mutating func keyChanged(kDown: Bool, at time: Date) {
        isKDown = kDown
        updateHolding(at: time)
    }

    public mutating func stateChanged(
        controlDown: Bool, optionDown: Bool,
        commandDown: Bool, kDown: Bool,
        at time: Date
    ) {
        isControlDown = controlDown
        isOptionDown = optionDown
        isCommandDown = commandDown
        isKDown = kDown
        updateHolding(at: time)
    }

    private mutating func updateHolding(at time: Date) {
        let allHeld = isControlDown && isOptionDown && isCommandDown && isKDown
        if allHeld && !isHolding {
            holdStartTime = time
            isHolding = true
        } else if !allHeld {
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
        isControlDown = false
        isOptionDown = false
        isCommandDown = false
        isKDown = false
    }
}
