import AppKit
import SwiftUI

@main
struct LiveFishTTSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var audioOutput = AudioOutputService()
    @StateObject private var speechQueue = SpeechQueueManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsStore)
                .environmentObject(audioOutput)
                .environmentObject(speechQueue)
                .task {
                    speechQueue.configure(
                        settingsStore: settingsStore,
                        apiClient: FishAudioClient(),
                        playbackService: AudioPlaybackService()
                    )
                    audioOutput.refreshDevices()
                }
        }
        .windowStyle(.titleBar)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
}
