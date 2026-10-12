import CoreGraphics
import ApplicationServices
import Foundation

public extension Notification.Name {
    static let escapeHoldStarted = Notification.Name("StandLock.escapeHoldStarted")
    static let escapeHoldEnded = Notification.Name("StandLock.escapeHoldEnded")
}

public final class EventTapController: @unchecked Sendable {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    public private(set) var isActive: Bool = false
    public private(set) var isBlocking: Bool = false
    private let onEscapeTriggered: @Sendable () -> Void
    var escapeDetector: EscapeDetector
    private var holdTimer: Timer?

    public init(
        escapeHoldDuration: TimeInterval = 10.0,
        onEscapeTriggered: @escaping @Sendable () -> Void
    ) {
        self.onEscapeTriggered = onEscapeTriggered
        self.escapeDetector = EscapeDetector(requiredDuration: escapeHoldDuration)
    }

    public var hasAccessibilityPermission: Bool { AXIsProcessTrusted() }
    public var hasInputMonitoringPermission: Bool { CGPreflightListenEventAccess() }

    public func startBlocking() {
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue) |
            (1 << CGEventType.mouseMoved.rawValue) |
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue) |
            (1 << CGEventType.scrollWheel.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: userInfo
        )

        if eventTap != nil {
            isBlocking = true
        } else {
            eventTap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .listenOnly,
                eventsOfInterest: eventMask,
                callback: eventTapCallback,
                userInfo: userInfo
            )
            isBlocking = false
        }

        guard let tap = eventTap else { return }
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isActive = true
    }

    public func stop() {
        cancelHoldTimer()
        escapeDetector.reset()
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        runLoopSource = nil
        eventTap = nil
        isActive = false
        isBlocking = false
    }

    func handleEvent(
        proxy: CGEventTapProxy, type: CGEventType, event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        let wasHolding = escapeDetector.isHolding

        if type == .tapDisabledByTimeout {
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            // Releases can fall in the gap while the tap is off. Forget what was held, or a key
            // that is no longer down would block the escape for the rest of the break.
            escapeDetector.reset()
            processHoldTransition(wasHolding: wasHolding)
            return Unmanaged.passUnretained(event)
        }

        let now = Date()
        switch type {
        case .flagsChanged:
            escapeDetector.flagsChanged(Self.modifiers(from: event.flags), at: now)
        case .keyDown:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            escapeDetector.keyChanged(keyCode: keyCode, isDown: true, at: now)
        case .keyUp:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            escapeDetector.keyChanged(keyCode: keyCode, isDown: false, at: now)
        default:
            return isBlocking ? nil : Unmanaged.passUnretained(event)
        }

        processHoldTransition(wasHolding: wasHolding)
        if type != .keyUp, escapeDetector.isEscapeTriggered(at: now) {
            cancelHoldTimer()
            onEscapeTriggered()
            return Unmanaged.passUnretained(event)
        }

        return isBlocking ? nil : Unmanaged.passUnretained(event)
    }

    /// Caps Lock is left out on purpose. It is a lock that stays on, not a key being held, and
    /// counting it would stop the escape from working for as long as it is on.
    static func modifiers(from flags: CGEventFlags) -> EscapeDetector.Modifiers {
        var modifiers: EscapeDetector.Modifiers = []
        if flags.contains(.maskControl) { modifiers.insert(.control) }
        if flags.contains(.maskAlternate) { modifiers.insert(.option) }
        if flags.contains(.maskCommand) { modifiers.insert(.command) }
        if flags.contains(.maskShift) { modifiers.insert(.shift) }
        if flags.contains(.maskSecondaryFn) { modifiers.insert(.function) }
        return modifiers
    }

    private func processHoldTransition(wasHolding: Bool) {
        if escapeDetector.isHolding && !wasHolding {
            startHoldTimer()
            NotificationCenter.default.post(name: .escapeHoldStarted, object: nil)
        } else if !escapeDetector.isHolding && wasHolding {
            cancelHoldTimer()
            NotificationCenter.default.post(name: .escapeHoldEnded, object: nil)
        }
    }

    private func startHoldTimer() {
        holdTimer = Timer.scheduledTimer(
            withTimeInterval: escapeDetector.requiredDuration + 0.01,
            repeats: false
        ) { [weak self] _ in
            guard let self else { return }
            if self.escapeDetector.isEscapeTriggered(at: Date()) {
                self.onEscapeTriggered()
            }
            self.holdTimer = nil
        }
    }

    private func cancelHoldTimer() {
        holdTimer?.invalidate()
        holdTimer = nil
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy, type: CGEventType, event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let controller = Unmanaged<EventTapController>.fromOpaque(userInfo).takeUnretainedValue()
    return controller.handleEvent(proxy: proxy, type: type, event: event)
}
