import SwiftUI

/// Applies the chosen language to a SwiftUI root.
///
/// The environment does not cross an `NSHostingView`: setting `.environment(\.locale, ...)`
/// on the value handed to `NSHostingView(rootView:)` captures the locale once and never
/// re-renders. The modifier has to sit inside a view that observes the store, which is what
/// this wrapper is for. Every root goes through it.
struct LocalizedRoot<Content: View>: View {
    @ObservedObject var store: LanguageStore
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .environment(\.locale, store.locale)
            .environmentObject(store)
    }
}
