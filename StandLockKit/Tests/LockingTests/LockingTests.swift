import Carbon.HIToolbox
import CoreGraphics
import Foundation
import Testing
@testable import Locking
@testable import StandLockCore

// MARK: - EscapeDetector Tests

@Suite("EscapeDetector Tests")
struct EscapeDetectorTests {
    /// A letter that is not part of the combination.
    private static let otherKey = Int64(kVK_ANSI_A)

    /// A detector with exactly the combination down since `start`.
    private func holdingDetector(since start: Date, duration: TimeInterval = 10) -> EscapeDetector {
        var detector = EscapeDetector(requiredDuration: duration)
        detector.flagsChanged(EscapeDetector.requiredModifiers, at: start)
        detector.keyChanged(keyCode: EscapeDetector.comboKeyCode, isDown: true, at: start)
        return detector
    }

    @Test func combinationIsControlOptionCommandShiftAndP() {
        #expect(EscapeDetector.requiredModifiers == [.control, .option, .command, .shift])
        #expect(EscapeDetector.comboKeyCode == Int64(kVK_ANSI_P))
    }

    @Test func combinationHeld10Seconds() {
        let start = Date()
        let detector = holdingDetector(since: start)
        #expect(detector.isHolding)
        #expect(!detector.isEscapeTriggered(at: start))
        #expect(!detector.isEscapeTriggered(at: start.addingTimeInterval(9.9)))
        #expect(detector.isEscapeTriggered(at: start.addingTimeInterval(10)))
    }

    @Test func modifiersOnlyDoesNotTrigger() {
        var detector = EscapeDetector(requiredDuration: 10)
        let start = Date()
        detector.flagsChanged(EscapeDetector.requiredModifiers, at: start)
        #expect(!detector.isHolding)
        #expect(!detector.isEscapeTriggered(at: start.addingTimeInterval(15)))
    }

    @Test func comboKeyOnlyDoesNotTrigger() {
        var detector = EscapeDetector(requiredDuration: 10)
        let start = Date()
        detector.keyChanged(keyCode: EscapeDetector.comboKeyCode, isDown: true, at: start)
        #expect(!detector.isHolding)
        #expect(!detector.isEscapeTriggered(at: start.addingTimeInterval(15)))
    }

    @Test func missingAnyOneModifierDoesNotTrigger() {
        let required: [EscapeDetector.Modifiers] = [.control, .option, .command, .shift]
        for missing in required {
            var detector = EscapeDetector(requiredDuration: 10)
            let start = Date()
            detector.flagsChanged(EscapeDetector.requiredModifiers.subtracting(missing), at: start)
            detector.keyChanged(keyCode: EscapeDetector.comboKeyCode, isDown: true, at: start)
            #expect(!detector.isHolding)
            #expect(!detector.isEscapeTriggered(at: start.addingTimeInterval(15)))
        }
    }

    @Test func holdInterruptedByReleasingComboKeyResetsTimer() {
        let start = Date()
        var detector = holdingDetector(since: start)
        #expect(detector.isHolding)

        let at8s = start.addingTimeInterval(8)
        detector.keyChanged(keyCode: EscapeDetector.comboKeyCode, isDown: false, at: at8s)
        #expect(!detector.isHolding)
        #expect(detector.holdStartTime == nil)

        let rehold = at8s.addingTimeInterval(1)
        detector.keyChanged(keyCode: EscapeDetector.comboKeyCode, isDown: true, at: rehold)
        #expect(!detector.isEscapeTriggered(at: rehold.addingTimeInterval(9)))
        #expect(detector.isEscapeTriggered(at: rehold.addingTimeInterval(10)))
    }

    @Test func holdInterruptedByReleasingModifierResetsTimer() {
        let start = Date()
        var detector = holdingDetector(since: start)
        #expect(detector.isHolding)

        let at8s = start.addingTimeInterval(8)
        detector.flagsChanged([.control, .command, .shift], at: at8s)
        #expect(!detector.isHolding)
        #expect(detector.holdStartTime == nil)

        let rehold = at8s.addingTimeInterval(1)
        detector.flagsChanged(EscapeDetector.requiredModifiers, at: rehold)
        #expect(!detector.isEscapeTriggered(at: rehold.addingTimeInterval(9)))
        #expect(detector.isEscapeTriggered(at: rehold.addingTimeInterval(10)))
    }

    @Test func pressingComboKeyFirstThenModifiersStartsHolding() {
        var detector = EscapeDetector(requiredDuration: 10)
        let start = Date()
        detector.keyChanged(keyCode: EscapeDetector.comboKeyCode, isDown: true, at: start)
        #expect(!detector.isHolding)

        let next = start.addingTimeInterval(1)
        detector.flagsChanged(EscapeDetector.requiredModifiers, at: next)
        #expect(detector.isHolding)
        #expect(!detector.isEscapeTriggered(at: next.addingTimeInterval(9)))
        #expect(detector.isEscapeTriggered(at: next.addingTimeInterval(10)))
    }

    @Test func keyRepeatOfComboKeyDoesNotRestartTheHold() {
        let start = Date()
        var detector = holdingDetector(since: start)

        detector.keyChanged(keyCode: EscapeDetector.comboKeyCode, isDown: true, at: start.addingTimeInterval(5))
        #expect(detector.holdStartTime == start)
        #expect(detector.isEscapeTriggered(at: start.addingTimeInterval(10)))
    }

    // MARK: Nothing but the combination

    @Test func theOldLetterTNoLongerCounts() {
        let tKey = Int64(kVK_ANSI_T)
        let start = Date()

        var onlyT = EscapeDetector(requiredDuration: 10)
        onlyT.flagsChanged(EscapeDetector.requiredModifiers, at: start)
        onlyT.keyChanged(keyCode: tKey, isDown: true, at: start)
        #expect(!onlyT.isHolding)
        #expect(!onlyT.isEscapeTriggered(at: start.addingTimeInterval(15)))

        var tAndP = holdingDetector(since: start)
        tAndP.keyChanged(keyCode: tKey, isDown: true, at: start.addingTimeInterval(1))
        #expect(!tAndP.isHolding)
        #expect(!tAndP.isEscapeTriggered(at: start.addingTimeInterval(15)))
    }

    @Test func anotherKeyHeldBeforeTheCombinationPreventsTheHold() {
        var detector = EscapeDetector(requiredDuration: 10)
        let start = Date()
        detector.keyChanged(keyCode: Self.otherKey, isDown: true, at: start)
        detector.flagsChanged(EscapeDetector.requiredModifiers, at: start)
        detector.keyChanged(keyCode: EscapeDetector.comboKeyCode, isDown: true, at: start)

        #expect(!detector.isHolding)
        #expect(detector.holdStartTime == nil)
        #expect(!detector.isEscapeTriggered(at: start.addingTimeInterval(60)))
    }

    @Test func anotherKeyPressedDuringTheHoldCancelsIt() {
        let start = Date()
        var detector = holdingDetector(since: start)
        #expect(detector.isHolding)

        let at8s = start.addingTimeInterval(8)
        detector.keyChanged(keyCode: Self.otherKey, isDown: true, at: at8s)
        #expect(!detector.isHolding)
        #expect(detector.holdStartTime == nil)
        #expect(!detector.isEscapeTriggered(at: start.addingTimeInterval(60)))
    }

    @Test func releasingTheOtherKeyStartsTheHoldAgainFromScratch() {
        let start = Date()
        var detector = holdingDetector(since: start)

        detector.keyChanged(keyCode: Self.otherKey, isDown: true, at: start.addingTimeInterval(8))
        let released = start.addingTimeInterval(9)
        detector.keyChanged(keyCode: Self.otherKey, isDown: false, at: released)

        #expect(detector.isHolding)
        #expect(detector.holdStartTime == released)
        #expect(!detector.isEscapeTriggered(at: released.addingTimeInterval(9.9)))
        #expect(detector.isEscapeTriggered(at: released.addingTimeInterval(10)))
    }

    @Test func keyRepeatOfAnotherKeyStillCountsAsOneKey() {
        let start = Date()
        var detector = holdingDetector(since: start)

        for second in 1...3 {
            detector.keyChanged(keyCode: Self.otherKey, isDown: true, at: start.addingTimeInterval(Double(second)))
        }
        #expect(!detector.isHolding)

        let released = start.addingTimeInterval(4)
        detector.keyChanged(keyCode: Self.otherKey, isDown: false, at: released)
        #expect(detector.isHolding)
        #expect(detector.holdStartTime == released)
    }

    @Test func everyKeyOnTheKeyboardDoesNotTrigger() {
        var detector = EscapeDetector(requiredDuration: 10)
        let start = Date()
        detector.flagsChanged(EscapeDetector.requiredModifiers, at: start)
        for keyCode in Int64(0)..<128 {
            detector.keyChanged(keyCode: keyCode, isDown: true, at: start)
        }

        #expect(!detector.isHolding)
        #expect(!detector.isEscapeTriggered(at: start.addingTimeInterval(600)))
    }

    @Test func letGoOfEverythingButTheCombinationStartsTheHold() {
        var detector = EscapeDetector(requiredDuration: 10)
        let start = Date()
        detector.flagsChanged(EscapeDetector.requiredModifiers, at: start)
        for keyCode in Int64(0)..<128 {
            detector.keyChanged(keyCode: keyCode, isDown: true, at: start)
        }
        #expect(!detector.isHolding)

        let letGo = start.addingTimeInterval(20)
        for keyCode in Int64(0)..<128 where keyCode != EscapeDetector.comboKeyCode {
            detector.keyChanged(keyCode: keyCode, isDown: false, at: letGo)
        }

        #expect(detector.isHolding)
        #expect(detector.holdStartTime == letGo)
        #expect(!detector.isEscapeTriggered(at: letGo.addingTimeInterval(9.9)))
        #expect(detector.isEscapeTriggered(at: letGo.addingTimeInterval(10)))
    }

    @Test func functionKeyHeldPreventsTheHold() {
        var detector = EscapeDetector(requiredDuration: 10)
        let start = Date()
        detector.flagsChanged(EscapeDetector.requiredModifiers.union(.function), at: start)
        detector.keyChanged(keyCode: EscapeDetector.comboKeyCode, isDown: true, at: start)

        #expect(!detector.isHolding)
        #expect(!detector.isEscapeTriggered(at: start.addingTimeInterval(60)))

        let released = start.addingTimeInterval(1)
        detector.flagsChanged(EscapeDetector.requiredModifiers, at: released)
        #expect(detector.isHolding)
        #expect(detector.holdStartTime == released)
    }

    @Test func releaseOfAKeyThatWasNeverSeenDownIsIgnored() {
        let start = Date()
        var detector = holdingDetector(since: start)

        detector.keyChanged(keyCode: Self.otherKey, isDown: false, at: start.addingTimeInterval(3))
        #expect(detector.isHolding)
        #expect(detector.holdStartTime == start)
    }

    // MARK: Reset

    @Test func resetForgetsEverythingThatWasHeld() {
        let start = Date()
        var detector = holdingDetector(since: start)
        detector.keyChanged(keyCode: Self.otherKey, isDown: true, at: start.addingTimeInterval(1))

        detector.reset()
        #expect(!detector.isHolding)
        #expect(detector.holdStartTime == nil)
        #expect(detector.modifiers.isEmpty)
        #expect(!detector.isComboKeyDown)
        #expect(detector.otherKeysDown.isEmpty)
    }

    @Test func aKeyForgottenByResetDoesNotBlockTheNextAttempt() {
        var detector = EscapeDetector(requiredDuration: 10)
        let start = Date()
        detector.keyChanged(keyCode: Self.otherKey, isDown: true, at: start)
        detector.reset()

        let attempt = start.addingTimeInterval(1)
        detector.flagsChanged(EscapeDetector.requiredModifiers, at: attempt)
        detector.keyChanged(keyCode: EscapeDetector.comboKeyCode, isDown: true, at: attempt)
        #expect(detector.isHolding)
        #expect(detector.isEscapeTriggered(at: attempt.addingTimeInterval(10)))
    }
}

// MARK: - EventTapController Tests

/// Feeds synthetic key events straight into the controller. Nothing is posted to the system.
@Suite("EventTapController Escape Tests")
struct EventTapControllerEscapeTests {
    /// Counts escapes from a callback that has to be `Sendable`.
    private final class Escapes: @unchecked Sendable {
        private let lock = NSLock()
        private var count = 0
        func record() { lock.withLock { count += 1 } }
        var total: Int { lock.withLock { count } }
    }

    private static let combination: CGEventFlags = [.maskControl, .maskAlternate, .maskCommand, .maskShift]
    private static let comboKey = EscapeDetector.comboKeyCode

    /// A controller that escapes the moment the combination is complete.
    private func makeController(escapes: Escapes) -> EventTapController {
        EventTapController(escapeHoldDuration: 0) { escapes.record() }
    }

    private func send(
        _ type: CGEventType, key: Int64 = 0, flags: CGEventFlags = [], to controller: EventTapController
    ) throws {
        let event = try #require(
            CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(key), keyDown: type != .keyUp)
        )
        event.flags = flags
        // handleEvent never reads the proxy.
        _ = controller.handleEvent(proxy: OpaquePointer(bitPattern: 1)!, type: type, event: event)
    }

    @Test func combinationTriggersTheEscape() throws {
        let escapes = Escapes()
        let controller = makeController(escapes: escapes)

        try send(.flagsChanged, flags: Self.combination, to: controller)
        try send(.keyDown, key: Self.comboKey, flags: Self.combination, to: controller)
        #expect(escapes.total == 1)
        controller.stop()
    }

    @Test func theOldLetterTDoesNotTriggerTheEscape() throws {
        let escapes = Escapes()
        let controller = makeController(escapes: escapes)

        try send(.flagsChanged, flags: Self.combination, to: controller)
        try send(.keyDown, key: Int64(kVK_ANSI_T), flags: Self.combination, to: controller)
        #expect(escapes.total == 0)
        controller.stop()
    }

    @Test func anotherKeyHeldDownPreventsTheEscape() throws {
        let escapes = Escapes()
        let controller = makeController(escapes: escapes)

        try send(.keyDown, key: Int64(kVK_ANSI_A), to: controller)
        try send(.flagsChanged, flags: Self.combination, to: controller)
        for _ in 0..<5 {
            try send(.keyDown, key: Self.comboKey, flags: Self.combination, to: controller)
        }
        #expect(escapes.total == 0)
        #expect(!controller.escapeDetector.isHolding)
        controller.stop()
    }

    @Test func pressingAnotherKeyEndsTheHoldAndReleasingItStartsAgain() throws {
        let escapes = Escapes()
        let controller = EventTapController(escapeHoldDuration: 3600) { escapes.record() }

        try send(.flagsChanged, flags: Self.combination, to: controller)
        try send(.keyDown, key: Self.comboKey, flags: Self.combination, to: controller)
        #expect(controller.escapeDetector.isHolding)

        try send(.keyDown, key: Int64(kVK_ANSI_A), flags: Self.combination, to: controller)
        #expect(!controller.escapeDetector.isHolding)

        try send(.keyUp, key: Int64(kVK_ANSI_A), flags: Self.combination, to: controller)
        #expect(controller.escapeDetector.isHolding)
        #expect(escapes.total == 0)
        controller.stop()
    }

    @Test func capsLockBeingOnDoesNotPreventTheEscape() throws {
        let escapes = Escapes()
        let controller = makeController(escapes: escapes)
        let withCapsLock = Self.combination.union(.maskAlphaShift)

        try send(.flagsChanged, flags: withCapsLock, to: controller)
        try send(.keyDown, key: Self.comboKey, flags: withCapsLock, to: controller)
        #expect(escapes.total == 1)
        controller.stop()
    }

    @Test func functionKeyHeldDownPreventsTheEscape() throws {
        let escapes = Escapes()
        let controller = makeController(escapes: escapes)
        let withFunction = Self.combination.union(.maskSecondaryFn)

        try send(.flagsChanged, flags: withFunction, to: controller)
        try send(.keyDown, key: Self.comboKey, flags: withFunction, to: controller)
        #expect(escapes.total == 0)
        controller.stop()
    }

    @Test func keysHeldBeforeATapOutageDoNotBlockTheEscapeAfterwards() throws {
        let escapes = Escapes()
        let controller = makeController(escapes: escapes)

        // The release of this key can fall in the gap while the tap is off.
        try send(.keyDown, key: Int64(kVK_ANSI_A), to: controller)
        try send(.tapDisabledByTimeout, to: controller)
        #expect(controller.escapeDetector.otherKeysDown.isEmpty)

        try send(.flagsChanged, flags: Self.combination, to: controller)
        try send(.keyDown, key: Self.comboKey, flags: Self.combination, to: controller)
        #expect(escapes.total == 1)
        controller.stop()
    }

    @Test func eventFlagsMapToTheModifiersOfTheCombination() {
        #expect(EventTapController.modifiers(from: Self.combination) == EscapeDetector.requiredModifiers)
        #expect(EventTapController.modifiers(from: []).isEmpty)
        #expect(EventTapController.modifiers(from: [.maskSecondaryFn]) == [.function])
    }

    @Test func capsLockIsNotAModifierOfTheCombination() {
        let flags = Self.combination.union([.maskAlphaShift, .maskNumericPad, .maskHelp])
        #expect(EventTapController.modifiers(from: flags) == EscapeDetector.requiredModifiers)
    }
}
