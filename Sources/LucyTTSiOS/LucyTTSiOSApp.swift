import SwiftUI

@main
struct LucyTTSiOSApp: App {
    @StateObject private var settingsStore = iOSSettingsStore()
    @StateObject private var speechQueue = iOSSpeechQueueManager()

    var body: some Scene {
        WindowGroup {
            iOSContentView()
                .environmentObject(settingsStore)
                .environmentObject(speechQueue)
                .tint(LucyTheme.hotPink)
                .task {
                    speechQueue.configure(
                        settingsStore: settingsStore,
                        apiClient: FishAudioClient(),
                        playbackService: iOSAudioPlaybackService()
                    )
                }
        }
    }
}
