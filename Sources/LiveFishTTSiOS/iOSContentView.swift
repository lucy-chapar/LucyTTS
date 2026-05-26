import SwiftUI

struct iOSContentView: View {
    @EnvironmentObject private var settingsStore: iOSSettingsStore
    @EnvironmentObject private var speechQueue: iOSSpeechQueueManager
    @State private var draftText = ""
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if settingsStore.hasUsableAPIKey {
                    mainInterface
                } else {
                    setupView
                }
            }
            .navigationTitle("Live Fish TTS")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings") {
                        showSettings = true
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Speak") {
                        submit()
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            iOSSettingsView()
                .environmentObject(settingsStore)
        }
    }

    private var mainInterface: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Voice: \(settingsStore.activeVoiceName)")
                    .font(.subheadline.weight(.medium))
                Text("\(speechQueue.status.label) · \(speechQueue.queuedCount) queued")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            iOSSubmitTextView(text: $draftText, onSubmit: submit)
                .font(.title3)
                .frame(minHeight: 220)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack {
                Button("Speak", action: submit)
                    .buttonStyle(.borderedProminent)
                Button("Stop current") {
                    speechQueue.stopCurrent()
                }
                Button("Clear queue") {
                    speechQueue.clearQueue()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let error = speechQueue.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            List {
                ForEach(speechQueue.items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.text)
                                .lineLimit(2)
                            Spacer()
                            Text(item.state.rawValue)
                                .font(.caption)
                                .foregroundStyle(item.state == .error ? .red : .secondary)
                        }
                        if let error = item.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        if item.state == .queued {
                            Button("Remove") {
                                speechQueue.removeQueuedItem(item)
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .padding()
    }

    private var setupView: some View {
        VStack(spacing: 14) {
            Text("Fish Audio API key required")
                .font(.title2.bold())
            Text("Save your key once. It stays in iOS Keychain.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open API Key Setup") {
                showSettings = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func submit() {
        let captured = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !captured.isEmpty else { return }
        speechQueue.enqueue(captured)
        draftText = ""
    }
}
