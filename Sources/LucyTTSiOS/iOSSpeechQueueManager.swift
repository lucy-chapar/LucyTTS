import Foundation

enum iOSSpeechItemState: String {
    case queued = "Queued"
    case generating = "Generating"
    case playing = "Playing"
    case done = "Done"
    case error = "Error"
}

struct iOSSpeechQueueItem: Identifiable, Equatable {
    let id = UUID()
    let text: String
    var state: iOSSpeechItemState = .queued
    var errorMessage: String?
}

enum iOSSpeechSystemStatus: Equatable {
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
final class iOSSpeechQueueManager: ObservableObject {
    @Published private(set) var items: [iOSSpeechQueueItem] = []
    @Published private(set) var status: iOSSpeechSystemStatus = .ready
    @Published private(set) var lastError: String?
    @Published private(set) var currentCaptionText: String?
    @Published private(set) var lastSpokenText: String?

    private weak var settingsStore: iOSSettingsStore?
    private var apiClient: FishAudioClient?
    private var playbackService: iOSAudioPlaybackService?
    private var processingTask: Task<Void, Never>?
    private var stoppingCurrent = false

    var queuedCount: Int {
        items.filter { $0.state == .queued }.count
    }

    func configure(settingsStore: iOSSettingsStore, apiClient: FishAudioClient, playbackService: iOSAudioPlaybackService) {
        self.settingsStore = settingsStore
        self.apiClient = apiClient
        self.playbackService = playbackService
    }

    func enqueue(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        items.append(iOSSpeechQueueItem(text: text))
        startProcessingIfNeeded()
    }

    func replayLastSpoken() {
        guard let lastSpokenText else { return }
        enqueue(lastSpokenText)
    }

    func removeQueuedItem(_ item: iOSSpeechQueueItem) {
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

    private func startProcessingIfNeeded() {
        guard processingTask == nil else { return }
        processingTask = Task { [weak self] in
            await self?.processLoop()
        }
    }

    private func processLoop() async {
        defer {
            processingTask = nil
            if case .error = status {
            } else {
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
                currentCaptionText = itemText
                items[nextIndex].state = .generating
                status = .generating
                let audio = try await apiClient.synthesize(
                    text: itemText,
                    apiKey: apiKey,
                    configuration: settingsStore.ttsConfiguration
                )
                guard let currentIndex = items.firstIndex(where: { $0.id == itemID }) else {
                    continue
                }
                items[currentIndex].state = .playing
                status = .playing
                try await playbackService.play(data: audio)
                if let doneIndex = items.firstIndex(where: { $0.id == itemID }) {
                    items[doneIndex].state = .done
                }
                lastSpokenText = itemText
                currentCaptionText = nil
                status = .ready
                lastError = nil
            } catch {
                if stoppingCurrent, (error as? iOSPlaybackError) == .stopped {
                    if let currentIndex = items.firstIndex(where: { $0.state == .playing || $0.state == .generating }) {
                        lastSpokenText = items[currentIndex].text
                        items[currentIndex].state = .done
                    }
                    currentCaptionText = nil
                    stoppingCurrent = false
                    status = .ready
                    continue
                }
                currentCaptionText = nil
                markItem(nextIndex, error: error.localizedDescription)
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
