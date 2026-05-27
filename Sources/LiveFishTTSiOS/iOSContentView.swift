import SwiftUI

struct iOSContentView: View {
    @EnvironmentObject private var settingsStore: iOSSettingsStore
    @EnvironmentObject private var speechQueue: iOSSpeechQueueManager
    @State private var draftText = ""
    @State private var draftSelection = NSRange(location: 0, length: 0)
    @State private var showSettings = false
    @State private var showEmotePicker = false

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

            mainContent

            if showEmotePicker {
                emoteOverlay
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            composerPanel
        }
        .animation(.easeInOut(duration: 0.16), value: showEmotePicker)
    }

    private var mainContent: some View {
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

            captionView
            historyList
        }
        .padding([.horizontal, .top])
    }

    private var composerPanel: some View {
        VStack(spacing: 10) {
            iOSSubmitTextView(text: $draftText, selectedRange: $draftSelection, onSubmit: submit)
                .font(.title3)
                .frame(minHeight: 150, maxHeight: 180)
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
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            LucyTheme.background
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(LucyTheme.hotPink.opacity(0.2))
                        .frame(height: 1)
                }
        )
    }

    private var commandButtons: some View {
        HStack(spacing: 8) {
            speakButton
            replayButton
            stopButton
            clearQueueButton
            emoteMenuButton
        }
        .font(.caption.weight(.semibold))
        .controlSize(.small)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var speakButton: some View {
        Button(action: submit) {
            Text("Speak")
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
            .buttonStyle(.borderedProminent)
            .tint(LucyTheme.hotPink)
    }

    private var replayButton: some View {
        Button {
            speechQueue.replayLastSpoken()
        } label: {
            Text("Replay")
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .buttonStyle(.bordered)
        .tint(LucyTheme.plum)
        .disabled(speechQueue.lastSpokenText == nil)
    }

    private var stopButton: some View {
        Button {
            speechQueue.stopCurrent()
        } label: {
            Text("Stop")
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .buttonStyle(.bordered)
        .tint(LucyTheme.plum)
    }

    private var clearQueueButton: some View {
        Button {
            speechQueue.clearQueue()
        } label: {
            Text("Clear")
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .buttonStyle(.bordered)
        .tint(LucyTheme.plum)
    }

    private var emoteMenuButton: some View {
        EmoteButton {
            showEmotePicker = true
        }
    }

    private var captionView: some View {
        Group {
            if let caption = speechQueue.currentCaptionText {
                Text(caption)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(LucyTheme.cream)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(LucyTheme.plum.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
    }

    private var historyList: some View {
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
        .frame(minHeight: 120)
    }

    private var emoteOverlay: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .onTapGesture {
                    showEmotePicker = false
                }

            iOSEmotePicker(
                onClose: {
                    showEmotePicker = false
                },
                onSelect: insertEmote
            )
            .padding(.horizontal, 12)
            .transition(.scale(scale: 0.98).combined(with: .opacity))
        }
        .zIndex(10)
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
        draftSelection = NSRange(location: 0, length: 0)
    }

    private func insertEmote(_ tag: String) {
        let insertion = "\(tag) "
        let original = draftText as NSString
        let range = clamped(draftSelection, in: original)
        draftText = original.replacingCharacters(in: range, with: insertion)
        draftSelection = NSRange(location: range.location + (insertion as NSString).length, length: 0)
        showEmotePicker = false
    }

    private func clamped(_ range: NSRange, in text: NSString) -> NSRange {
        let location = min(max(range.location, 0), text.length)
        let length = min(max(range.length, 0), text.length - location)
        return NSRange(location: location, length: length)
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

private struct PhraseCatalogTab: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var phrases: [PhraseCatalogPhrase]
}

private struct PhraseCatalogPhrase: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var text: String
}

private let starterPhraseCatalogTabs = [
    PhraseCatalogTab(name: "Quick", phrases: []),
    PhraseCatalogTab(name: "Care", phrases: []),
    PhraseCatalogTab(name: "Meeting", phrases: [])
]

private struct EmoteButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Emote")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
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
        GridItem(.flexible(minimum: 78), spacing: 8),
        GridItem(.flexible(minimum: 78), spacing: 8),
        GridItem(.flexible(minimum: 78), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Emote")
                    .font(.headline)
                    .foregroundStyle(LucyTheme.plum)
                Spacer()
                Button("Close", action: onClose)
                    .font(.callout.weight(.semibold))
                    .tint(LucyTheme.plum)
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(fishEmoteTags, id: \.self) { tag in
                    Button {
                        onSelect(tag)
                    } label: {
                        Text(tag)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(LucyTheme.hotPink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .padding(.horizontal, 6)
                            .background(LucyTheme.hotPink.opacity(0.22))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(LucyTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(LucyTheme.hotPink.opacity(0.26), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
    }
}
