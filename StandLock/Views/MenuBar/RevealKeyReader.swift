import AppKit
import SwiftUI

/// Reports whether ⌥ is held while the menu bar panel is open.
///
/// The panel is built once and reused, so SwiftUI's `onAppear` does not run on every opening.
/// This watches the panel's own window instead. The keyboard is sampled only while that window
/// is key, and the flag is cleared when it resigns, so every opening starts from "not held" and
/// a stale reading can never carry over to the next one.
struct RevealKeyReader: NSViewRepresentable {
    @Binding var isHeld: Bool

    func makeNSView(context: Context) -> RevealKeyView {
        let view = RevealKeyView()
        view.onChange = { isHeld = $0 }
        return view
    }

    func updateNSView(_ view: RevealKeyView, context: Context) {
        view.onChange = { isHeld = $0 }
    }

    static func dismantleNSView(_ view: RevealKeyView, coordinator: ()) {
        view.stop()
    }
}

final class RevealKeyView: NSView {
    var onChange: (Bool) -> Void = { _ in }

    private var observers: [NSObjectProtocol] = []
    private var timer: Timer?
    private var isHeld = false

    /// Never take clicks from the content it sits behind.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stop()
        guard let window else { return }

        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.beginSampling() }
            },
            center.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.endSampling() }
            },
        ]

        // Attached while already key: sample once SwiftUI has finished the update that
        // attached it, not during it.
        if window.isKeyWindow {
            Task { @MainActor [weak self] in self?.beginSampling() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers = []
    }

    private func beginSampling() {
        sample()
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.sample() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func endSampling() {
        timer?.invalidate()
        timer = nil
        update(false)
    }

    private func sample() {
        update(NSEvent.modifierFlags.contains(.option))
    }

    private func update(_ held: Bool) {
        guard held != isHeld else { return }
        isHeld = held
        onChange(held)
    }
}
