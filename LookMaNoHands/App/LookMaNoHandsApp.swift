import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleDictation = Self("toggleDictation", default: .init(.space, modifiers: .option))
    static let readSelection = Self("readSelection", default: .init(.s, modifiers: .option))
}

@main
struct LookMaNoHandsApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            Image(systemName: appState.menuBarIcon)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }

    init() {
        setupHotkeys()
    }

    private func setupHotkeys() {
        KeyboardShortcuts.onKeyUp(for: .toggleDictation) { [appState] in
            Task { @MainActor in
                await appState.toggleDictation()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .readSelection) { [appState] in
            Task { @MainActor in
                await appState.toggleReading()
            }
        }
    }
}
