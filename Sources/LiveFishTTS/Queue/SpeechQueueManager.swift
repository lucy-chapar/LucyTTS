import Foundation

enum SpeechItemState: String {
    case queued = "Queued"
    case generating = "Generating"
    case playing = "Playing"
    case done = "Done"
    case error = "Error"
}

struct SpeechQueueItem: Identifiable, Equatable {
    let id = UUID()
    let text: String
    var state: SpeechItemState = .queued
    var errorMessage: String?
}

enum SpeechSystemStatus: Equatable {
    case ready
    case generating
    case playing
    case error(String)

    var label: String {
        switch self {
        case .ready:
            return "Ready"
        case .generating:
            return "Generating"
        case .playing:
            return "Playing"
        case .error:
            return "Error"
        }
    }
}

@MainActor
final class SpeechQueueManager: ObservableObject {
    @Published private(set) var items: [SpeechQueueItem] = []
    @Published private(set) var status: SpeechSystemStatus = .ready
    @Published private(set) var lastError: String?

    private weak var settingsStore: SettingsStore?
    private var apiClient: FishAudioClient?
    private var playbackService: AudioPlaybackService?
    private var processingTask: Task<Void, Never>?
    private var stoppingCurrent = false

    var queuedCount: Int {
        items.filter { $0.state == .queued }.count
    }

    func configure(settingsStore: SettingsStore, apiClient: FishAudioClient, playbackService: AudioPlaybackService) {
        self.settingsStore = settingsStore
        self.apiClient = apiClient
        self.playbackService = playbackService
    }

    func enqueue(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        items.append(SpeechQueueItem(text: text))
        startProcessingIfNeeded()
    }

    func removeQueuedItem(_ item: SpeechQueueItem) {
        guard item.state == .queued else { return }
        items.removeAll { $0.id == item.id && $0.state == .queued }
    }

    func clearQueue() {
        items.removeAll { $0.state == .queued }
    }

    func stopCurrent() {
        stoppingCurrent = true
        playbackService?.stopCurrent()
    }

    func testMeetingAudio() {
        enqueue("Testing meeting audio.")
    }

    private func startProcessingIfNeeded() {
        guard processingTask == nil else { return }
        processingTask = Task { [weak self] in
            await self?.processLoop()
        }
    }

    private func processLoop() async {
        defer {
            processingTask = nil
            if status != .error(lastError ?? "") {
                status = .ready
            }
        }

        while let nextIndex = items.firstIndex(where: { $0.state == .queued }) {
            guard let settingsStore, let apiClient, let playbackService else {
                markItem(nextIndex, error: "App services are not ready.")
                continue
            }

            do {
                let itemID = items[nextIndex].id
                let itemText = items[nextIndex].text
                let apiKey = try settingsStore.currentAPIKey()
                items[nextIndex].state = .generating
                status = .generating
                let config = settingsStore.ttsConfiguration
                let outputDeviceID = settingsStore.selectedOutputDeviceID
                let audio = try await apiClient.synthesize(
                    text: itemText,
                    apiKey: apiKey,
                    configuration: config
                )

                guard let currentIndex = items.firstIndex(where: { $0.id == itemID }) else {
                    continue
                }
                items[currentIndex].state = .playing
                status = .playing
                try await playbackService.play(
                    data: audio,
                    outputDeviceID: outputDeviceID == AudioDevice.defaultID ? nil : outputDeviceID
                )
                if let doneIndex = items.firstIndex(where: { $0.id == itemID }) {
                    items[doneIndex].state = .done
                }
                status = .ready
                lastError = nil
            } catch {
                let reason = error.localizedDescription
                if stoppingCurrent, (error as? PlaybackError) == .stopped {
                    if let currentIndex = items.firstIndex(where: { $0.state == .playing || $0.state == .generating }) {
                        items[currentIndex].state = .done
                    }
                    stoppingCurrent = false
                    status = .ready
                    continue
                }
                markItem(nextIndex, error: reason)
            }
        }
    }

    private func markItem(_ index: Int, error: String) {
        guard items.indices.contains(index) else { return }
        items[index].state = .error
        items[index].errorMessage = error
        lastError = error
        status = .error(error)
    }
}
