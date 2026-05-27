import AVFoundation
import SwiftUI

@main
struct LucyTTSiOSApp: App {
    @StateObject private var settingsStore = iOSSettingsStore()
    @StateObject private var speechQueue = iOSSpeechQueueManager()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        configureAudioSession()
    }

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
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                activateAudioSession()
            case .background:
                deactivateAudioSession()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }

    /// Configure the iOS audio session for spoken-audio playback. With this
    /// session active, the iPhone's hardware volume buttons control media
    /// (speaker) volume instead of ringer volume while Lucy is open, even
    /// in the gaps between sentences.
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            // Non-fatal: TTS playback still works; the only visible symptom
            // is that volume buttons may fall back to ringer routing while
            // nothing is currently playing.
        }
    }

    private func activateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance()
            .setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
