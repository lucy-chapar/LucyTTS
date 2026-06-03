import SwiftUI
import UniformTypeIdentifiers

struct STTContentView: View {
    @EnvironmentObject private var session: TranscriptionSessionManager
    @EnvironmentObject private var keyStore: DeepgramKeyStore
    @State private var showSetupHelp = false
    @State private var showLiveRecording = false
    @State private var apiKeyDraft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            apiKeySection
            fileSection
            speakerFields
            controlRow
            statusRow
            transcriptArea

            DisclosureGroup("Record live instead", isExpanded: $showLiveRecording) {
                liveRecordingSection
            }
            .foregroundStyle(STTTheme.textSecondary)
        }
        .padding(20)
        .frame(minWidth: 640, minHeight: 560)
        .background(
            LinearGradient(
                colors: [STTTheme.cream, STTTheme.blush.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .preferredColorScheme(.light)
        .sheet(isPresented: $showSetupHelp) {
            SetupHelpView()
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Lucy STT")
                    .font(.title2.bold())
                    .foregroundStyle(STTTheme.text)
                Text("Two-speaker play-style transcripts")
                    .font(.caption)
                    .foregroundStyle(STTTheme.textSecondary)
            }
            Spacer()
            Button("Help") { showSetupHelp = true }
                .foregroundStyle(STTTheme.text)
        }
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Deepgram API key")
                .font(.headline)
                .foregroundStyle(STTTheme.text)

            if keyStore.hasKey {
                Text("Saved: \(keyStore.maskedKey ?? "•••••")")
                    .foregroundStyle(STTTheme.textSecondary)
            } else {
                SecureField("Paste Deepgram API key", text: $apiKeyDraft)
                    .textFieldStyle(.roundedBorder)
                Button("Save key") {
                    keyStore.saveAPIKey(apiKeyDraft)
                    apiKeyDraft = ""
                }
                .disabled(apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Text("Get a key at console.deepgram.com. Audio is sent to Deepgram for transcription with speaker labels.")
                .font(.caption)
                .foregroundStyle(STTTheme.textMuted)

            if let error = keyStore.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var fileSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button("Choose recording…") {
                    session.chooseRecordingFile()
                }
                .buttonStyle(.borderedProminent)
                .tint(STTTheme.hotPink)
                .disabled(session.phase == .transcribing || session.isRecording)

                if let name = session.selectedFileName {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(STTTheme.text)
                        if let size = session.selectedFileSizeLabel {
                            Text(size)
                                .font(.caption)
                                .foregroundStyle(STTTheme.textMuted)
                        }
                    }
                }
            }

            Text("Drop an audio file here (m4a, mp3, wav, etc.). Long sessions may take several minutes.")
                .font(.caption)
                .foregroundStyle(STTTheme.textMuted)
        }
        .padding(12)
        .background(STTTheme.cream.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var speakerFields: some View {
        HStack(spacing: 16) {
            labeledField("Speaker 1 label", text: $session.speakerOneName)
            labeledField("Speaker 2 label", text: $session.speakerTwoName)
        }
    }

    private func labeledField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(STTTheme.textSecondary)
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
                .disabled(session.isRecording || session.phase == .transcribing)
        }
    }

    private var liveRecordingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Input")
                    .foregroundStyle(STTTheme.textSecondary)
                Picker("Input", selection: $session.selectedInputDeviceID) {
                    ForEach(session.inputDevices) { device in
                        Text(device.name).tag(device.id)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 360)
                Button("Refresh") { session.refreshDevices() }
                    .foregroundStyle(STTTheme.text)
            }

            if session.isRecording {
                Button("Stop & transcribe") {
                    session.stopAndTranscribe()
                }
                .buttonStyle(.borderedProminent)
                .tint(STTTheme.hotPink)
            } else {
                Button("Start recording") {
                    session.startRecording()
                }
                .buttonStyle(.bordered)
                .disabled(session.phase == .transcribing)
            }
        }
        .padding(.top, 8)
    }

    private var controlRow: some View {
        HStack(spacing: 12) {
            if session.hasSelectedFile && !session.isRecording {
                Button("Transcribe") {
                    session.transcribeSelectedFile()
                }
                .buttonStyle(.borderedProminent)
                .tint(STTTheme.hotPink)
                .disabled(session.phase == .transcribing || !keyStore.hasKey)
            }

            if session.phase == .done {
                Button("Copy") { session.copyTranscript() }
                Button("Save…") { session.saveTranscript() }
                Button("New file") { session.reset() }
            }
        }
    }

    private var statusRow: some View {
        HStack {
            if session.isRecording {
                Text("Recording \(formattedElapsed(session.elapsedSeconds))")
                    .font(.headline)
                    .foregroundStyle(STTTheme.hotPink)
            } else if session.phase == .transcribing {
                ProgressView()
                Text("Transcribing…")
                    .foregroundStyle(STTTheme.textSecondary)
            } else if case .error(let message) = session.phase {
                Text(message)
                    .foregroundStyle(.red)
            } else if !session.statusNote.isEmpty {
                Text(session.statusNote)
                    .font(.caption)
                    .foregroundStyle(STTTheme.textMuted)
            }
            Spacer()
        }
    }

    private var transcriptArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            if session.canSwapSpeakers {
                HStack {
                    Text("Transcript")
                        .font(.headline)
                        .foregroundStyle(STTTheme.text)
                    Spacer()
                    Button("Swap speakers") {
                        session.swapSpeakerIdentities()
                    }
                    .help("Exchange Speaker 1 and Speaker 2 labels in the transcript")
                }
            }

            Group {
                if session.transcript.isEmpty {
                    Text("Choose a recording and click Transcribe. Output looks like a play script with labeled speaker blocks.")
                        .foregroundStyle(STTTheme.textMuted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else {
                    ScrollView {
                        Text(session.transcript)
                            .foregroundStyle(STTTheme.text)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(14)
        .background(Color.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(STTTheme.plum.opacity(0.15), lineWidth: 1)
        )
    }

    private func formattedElapsed(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let minutes = total / 60
        let remainder = total % 60
        return String(format: "%d:%02d", minutes, remainder)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil)
            else { return }

            Task { @MainActor in
                session.loadRecording(from: url)
            }
        }
        return true
    }
}

private struct SetupHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("How to use Lucy STT")
                    .font(.title2.bold())
                    .foregroundStyle(STTTheme.text)

                Group {
                    Text("1. Create a Deepgram API key at console.deepgram.com and save it here.")
                    Text("2. Choose a recording or drag it onto the window.")
                    Text("3. Set speaker labels (defaults: Me and Therapist).")
                    Text("4. Click Transcribe. Long sessions may take several minutes.")
                    Text("5. Copy or save the play-style transcript.")
                }
                .foregroundStyle(STTTheme.textSecondary)

                Button("Close") { dismiss() }
                    .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 520, height: 320)
    }
}
