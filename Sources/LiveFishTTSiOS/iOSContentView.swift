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
            .navigationTitle("Lucy TTS")
            .toolbarBackground(LucyTheme.blush.opacity(0.82), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
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
        ZStack {
            LucyTheme.background
                .ignoresSafeArea()

            VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Voice: \(settingsStore.activeVoiceName)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(LucyTheme.plum)
                Text("\(speechQueue.status.label) · \(speechQueue.queuedCount) queued")
                    .font(.caption)
                    .foregroundStyle(LucyTheme.plum.opacity(0.72))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            iOSSubmitTextView(text: $draftText, onSubmit: submit)
                .font(.title3)
                .frame(minHeight: 220)
                .padding(8)
                .background(LucyTheme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(LucyTheme.plum.opacity(0.52), lineWidth: 2)
                )

            HStack {
                Button("Speak", action: submit)
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
                                .foregroundStyle(LucyTheme.plum)
                            Spacer()
                            Text(item.state.rawValue)
                                .font(.caption)
                                .foregroundStyle(item.state == .error ? .red : LucyTheme.plum.opacity(0.68))
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
                    .listRowBackground(LucyTheme.cream.opacity(0.82))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
    }

    private var setupView: some View {
        ZStack {
            LucyTheme.background
                .ignoresSafeArea()

            VStack(spacing: 14) {
            Text("Fish Audio API key required")
                .font(.title2.bold())
                .foregroundStyle(LucyTheme.plum)
            Text("Save your key once. It stays in iOS Keychain.")
                .foregroundStyle(LucyTheme.plum.opacity(0.72))
                .multilineTextAlignment(.center)
            Button("Open API Key Setup") {
                showSettings = true
            }
            .buttonStyle(.borderedProminent)
            .tint(LucyTheme.hotPink)
            }
            .padding()
        }
    }

    private func submit() {
        let captured = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !captured.isEmpty else { return }
        speechQueue.enqueue(captured)
        draftText = ""
    }
}
