import SwiftUI

struct iOSContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var settingsStore: iOSSettingsStore
    @EnvironmentObject private var speechQueue: iOSSpeechQueueManager
    @State private var draftText = ""
    @State private var showSettings = false
    @State private var showEmotePicker = false
    @State private var pendingTextInsertion: String?

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
        .sheet(isPresented: $showEmotePicker) {
            iOSEmotePicker(
                onClose: {
                    showEmotePicker = false
                },
                onSelect: insertEmote
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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

            iOSSubmitTextView(text: $draftText, pendingInsertion: $pendingTextInsertion, onSubmit: submit)
                .font(.title3)
                .frame(minHeight: 220)
                .padding(8)
                .background(LucyTheme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(LucyTheme.plum.opacity(0.52), lineWidth: 2)
                )

            commandButtons

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

    private var commandButtons: some View {
        Group {
            if horizontalSizeClass == .compact {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        speakButton
                        stopButton
                    }
                    HStack(spacing: 12) {
                        clearQueueButton
                        emoteMenuButton
                    }
                }
            } else {
                HStack(spacing: 12) {
                    speakButton
                    stopButton
                    clearQueueButton
                    emoteMenuButton
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var speakButton: some View {
        Button("Speak", action: submit)
            .buttonStyle(.borderedProminent)
            .tint(LucyTheme.hotPink)
    }

    private var stopButton: some View {
        Button("Stop current") {
            speechQueue.stopCurrent()
        }
        .tint(LucyTheme.plum)
    }

    private var clearQueueButton: some View {
        Button("Clear queue") {
            speechQueue.clearQueue()
        }
        .tint(LucyTheme.plum)
    }

    private var emoteMenuButton: some View {
        EmoteButton {
            showEmotePicker = true
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

    private func insertEmote(_ tag: String) {
        pendingTextInsertion = "\(tag) "
        showEmotePicker = false
    }
}

private let fishEmoteTags = [
    "[laughing]",
    "[chuckling]",
    "[moaning]",
    "[clear throat]",
    "[sobbing]",
    "[crying loudly]",
    "[sighing]",
    "[panting]",
    "[groaning]",
    "[crowd laughing]",
    "[background laughter]",
    "[audience laughing]",
    "[pause]",
    "[long pause]"
]

private struct EmoteButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Emote")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [.red, .orange, .yellow, .green, .blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct iOSEmotePicker: View {
    var onClose: () -> Void
    var onSelect: (String) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 148), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LucyTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(fishEmoteTags, id: \.self) { tag in
                            Button {
                                onSelect(tag)
                            } label: {
                                Text(tag)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(LucyTheme.hotPink)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.82)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .padding(.horizontal, 12)
                                    .background(LucyTheme.hotPink.opacity(0.22))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Emote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", action: onClose)
                        .tint(LucyTheme.plum)
                }
            }
        }
    }
}
