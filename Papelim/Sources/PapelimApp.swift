import SwiftUI
import AppKit
import PapelimCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // When launched via `swift run` (no .app bundle) macOS does not treat
        // the process as a regular GUI app, so the window never becomes key
        // and key events go to the terminal instead of the text view.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct PapelimApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = SnippetStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 900, minHeight: 560)
                .task { await store.loadAll() }
        }
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Snippet") { store.createNew() }
                    .keyboardShortcut("n", modifiers: [.command])
            }
            CommandGroup(replacing: .appSettings) {
                Button("Storage Locations…") { store.showingSettings = true }
                    .keyboardShortcut(",", modifiers: [.command])
            }
        }
    }
}
