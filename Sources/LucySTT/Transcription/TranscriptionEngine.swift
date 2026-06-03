import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class TranscriptionSessionManager: ObservableObject {
    enum Phase: Equatable {
        case idle
        case recording
        case transcribing
        case done
        case error(String)
    }

    @Published var phase: Phase = .idle
    @Published var transcript = ""
    @Published var statusNote = ""
    @Published var speakerOneName = "Me"
    @Published var speakerTwoName = "Therapist"
    @Published var selectedInputDeviceID = AudioInputDevice.defaultID
    @Published var selectedFileName: String?
    @Published var selectedFileSizeLabel: String?

    private let recorder = SessionRecorder()
    private let audioInput = AudioInputService()
    private let deepgramClient = DeepgramASRClient()
    private var selectedFileURL: URL?
    private var cachedUtterances: [DeepgramUtterance] = []
    private weak var keyStore: DeepgramKeyStore?

    var isRecording: Bool { recorder.isRecording }
    var elapsedSeconds: TimeInterval { recorder.elapsedSeconds }
    var inputDevices: [AudioInputDevice] { audioInput.devices }
    var hasSelectedFile: Bool { selectedFileURL != nil }
    var canSwapSpeakers: Bool { !cachedUtterances.isEmpty }

    func configure(keyStore: DeepgramKeyStore) {
        self.keyStore = keyStore
    }

    func refreshDevices() {
        audioInput.refreshDevices()
    }

    func chooseRecordingFile() {
        let panel = NSOpenPanel()
        panel.title = "Choose a recording"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.audio, .mpeg4Audio, .mp3, .wav, .aiff]
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                self?.loadRecording(from: url)
            }
        }
    }

    func loadRecording(from url: URL) {
        selectedFileURL = url
        selectedFileName = url.lastPathComponent
        selectedFileSizeLabel = AudioFileInfo.formattedSize(for: url)
        transcript = ""
        cachedUtterances = []
        statusNote = ""
        phase = .idle
    }

    func transcribeSelectedFile() {
        guard let url = selectedFileURL else { return }
        transcribe(url: url)
    }

    func startRecording() {
        guard phase != .recording else { return }
        transcript = ""
        cachedUtterances = []
        statusNote = ""

        Task {
            do {
                _ = try await recorder.start(inputDeviceID: selectedInputDeviceID)
                phase = .recording
            } catch {
                phase = .error(error.localizedDescription)
            }
        }
    }

    func stopAndTranscribe() {
        guard phase == .recording else { return }

        guard let recordingURL = recorder.stop() else {
            phase = .error("Recording file was missing.")
            return
        }

        selectedFileURL = recordingURL
        selectedFileName = recordingURL.lastPathComponent
        selectedFileSizeLabel = AudioFileInfo.formattedSize(for: recordingURL)
        transcribe(url: recordingURL)
    }

    private func transcribe(url: URL) {
        guard let keyStore else {
            phase = .error("App services are not ready.")
            return
        }

        let accessed = url.startAccessingSecurityScopedResource()

        phase = .transcribing
        let onDiskSize = AudioFileInfo.formattedSize(for: url)
        statusNote = "Preparing \(onDiskSize) for transcription…"

        Task {
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let apiKey = try keyStore.currentAPIKey()
                let utterances = try await deepgramClient.transcribe(
                    audioURL: url,
                    apiKey: apiKey
                ) { [weak self] note in
                    Task { @MainActor in self?.statusNote = note }
                }

                transcript = PlayTranscriptFormatter.format(
                    utterances: utterances,
                    speakerOneName: speakerOneName,
                    speakerTwoName: speakerTwoName
                )
                cachedUtterances = utterances
                statusNote = "Done — play-style transcript with speaker labels."
                phase = .done
            } catch {
                phase = .error(error.localizedDescription)
            }
        }
    }

    func copyTranscript() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcript, forType: .string)
    }

    func swapSpeakerIdentities() {
        guard !cachedUtterances.isEmpty else { return }
        let previousOne = speakerOneName
        speakerOneName = speakerTwoName
        speakerTwoName = previousOne
        transcript = PlayTranscriptFormatter.format(
            utterances: cachedUtterances,
            speakerOneName: speakerOneName,
            speakerTwoName: speakerTwoName
        )
    }

    func saveTranscript() {
        let panel = NSSavePanel()
        panel.title = "Save transcript"
        panel.nameFieldStringValue = "therapy-transcript.txt"
        panel.allowedContentTypes = [.plainText]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? self.transcript.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    func reset() {
        transcript = ""
        cachedUtterances = []
        statusNote = ""
        selectedFileURL = nil
        selectedFileName = nil
        selectedFileSizeLabel = nil
        phase = .idle
    }
}
