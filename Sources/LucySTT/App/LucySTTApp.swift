import AppKit
import SwiftUI

@main
struct LucySTTApp: App {
    @NSApplicationDelegateAdaptor(STTAppDelegate.self) private var appDelegate
    @StateObject private var session = TranscriptionSessionManager()
    @StateObject private var keyStore = DeepgramKeyStore()

    var body: some Scene {
        WindowGroup {
            STTContentView()
                .environmentObject(session)
                .environmentObject(keyStore)
                .tint(STTTheme.hotPink)
                .task {
                    keyStore.refresh()
                    session.configure(keyStore: keyStore)
                    session.refreshDevices()
                }
        }
        .windowStyle(.titleBar)
    }
}

final class STTAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
}
