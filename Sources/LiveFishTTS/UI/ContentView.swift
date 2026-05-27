import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var audioOutput: AudioOutputService
    @EnvironmentObject private var speechQueue: SpeechQueueManager
    @State private var draftText = ""
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle()
                .fill(LucyTheme.hotPink.opacity(0.35))
                .frame(height: 1)
            if settingsStore.hasUsableAPIKey {
                mainInterface
            } else {
                SetupView(showSettings: $showSettings)
            }
        }
        .background(LucyTheme.background)
        .frame(minWidth: 820, minHeight: 620)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(settingsStore)
                .environmentObject(audioOutput)
                .environmentObject(speechQueue)
        }
    }

    private var header: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(LucyTheme.plum)
                Text("L")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(LucyTheme.cream)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text("Lucy TTS")
                    .font(.title2.bold())
                    .foregroundStyle(LucyTheme.plum)
                Text(routeSummary)
                    .font(.caption)
                    .foregroundStyle(LucyTheme.plum.opacity(0.72))
            }
            Spacer()
            StatusPill(text: speechQueue.status.label)
            Text("\(speechQueue.queuedCount) queued")
                .foregroundStyle(LucyTheme.plum.opacity(0.72))
            Button("Settings") {
                showSettings = true
            }
            .tint(LucyTheme.plum)
        }
        .padding()
    }

    private var mainInterface: some View {
        VStack(spacing: 14) {
            SubmitTextView(
                text: $draftText,
                placeholder: "Type what you want to say...",
                checkSpelling: settingsStore.checkSpelling,
                autoCorrectSpelling: settingsStore.autoCorrectSpelling,
                checkGrammar: settingsStore.checkGrammar,
                onSubmit: submit
            )
            .background(LucyTheme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(LucyTheme.plum.opacity(0.45), lineWidth: 2)
            )
            .frame(minHeight: 210)

            HStack {
                Button("Speak", action: submit)
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
                    .tint(LucyTheme.hotPink)
                Button("Stop current") {
                    speechQueue.stopCurrent()
                }
                .tint(LucyTheme.plum)
                Button("Clear queue") {
                    speechQueue.clearQueue()
                }
                .tint(LucyTheme.plum)
                Spacer()
                if let error = speechQueue.lastError {
                    Text(error)
                        .lineLimit(1)
                        .foregroundStyle(.red)
                }
            }

            queueList
        }
        .padding()
    }

    private var queueList: some View {
        List {
            ForEach(speechQueue.items) { item in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.text)
                            .lineLimit(2)
                        if let error = item.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    Spacer()
                    Text(item.state.rawValue)
                        .font(.caption)
                        .foregroundStyle(item.state == .error ? .red : .secondary)
                    if item.state == .queued {
                        Button("Remove") {
                            speechQueue.removeQueuedItem(item)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .background(LucyTheme.cream.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(minHeight: 220)
    }

    private var routeSummary: String {
        let name = audioOutput.deviceName(for: settingsStore.selectedOutputDeviceID)
        return "Voice: \(settingsStore.activeVoiceName) · Output: \(name) · Meeting Mode: \(settingsStore.meetingModeEnabled ? "On" : "Off")"
    }

    private func submit() {
        let captured = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !captured.isEmpty else { return }
        speechQueue.enqueue(captured)
        draftText = ""
    }
}

private struct StatusPill: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(LucyTheme.cream)
            .background(LucyTheme.plum)
            .clipShape(Capsule())
    }
}

private struct SetupView: View {
    @Binding var showSettings: Bool

    var body: some View {
        VStack(spacing: 14) {
            Text("Fish Audio API key required")
                .font(.title2.bold())
                .foregroundStyle(LucyTheme.plum)
            Text("Paste your key once. It will be stored in macOS Keychain and the app can launch normally after that.")
                .foregroundStyle(LucyTheme.plum.opacity(0.72))
                .multilineTextAlignment(.center)
            Button("Open API Key Setup") {
                showSettings = true
            }
            .buttonStyle(.borderedProminent)
            .tint(LucyTheme.hotPink)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
