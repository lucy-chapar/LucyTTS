import SwiftUI

struct iOSContentView: View {
    @EnvironmentObject private var settingsStore: iOSSettingsStore
    @EnvironmentObject private var speechQueue: iOSSpeechQueueManager
    @State private var draftText = ""
    @State private var draftSelection = NSRange(location: 0, length: 0)
    @State private var draftEditorHeight: CGFloat = 76
    @State private var editorIsFocused = true
    @State private var showSettings = false
    @State private var showEmotePicker = false
    @State private var showPhraseCatalog = false

    var body: some View {
        NavigationStack {
            Group {
                if settingsStore.hasUsableAPIKey {
                    mainInterface
                } else {
                    setupView
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
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
        .sheet(isPresented: $showPhraseCatalog) {
            iOSPhraseCatalogView(
                items: speechQueue.items,
                onClose: {
                    showPhraseCatalog = false
                },
                onSelectPhrase: insertPhrase
            )
        }
    }

    private var mainInterface: some View {
        ZStack {
            LucyTheme.background
                .ignoresSafeArea()

            mainContent
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            composerPanel
        }
        .animation(.easeInOut(duration: 0.16), value: showEmotePicker)
    }

    private var mainContent: some View {
        VStack(spacing: 12) {
            header
            captionView
            Spacer(minLength: 0)
        }
        .padding([.horizontal, .top])
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Lucy TTS")
                    .font(.title2.bold())
                    .foregroundStyle(.black)
                Text("Voice: \(settingsStore.activeVoiceName) · \(speechQueue.status.label) · \(speechQueue.queuedCount) queued")
                    .font(.subheadline)
                    .foregroundStyle(LucyTheme.plum.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            Button("Settings") {
                editorIsFocused = false
                showSettings = true
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(LucyTheme.hotPink)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(LucyTheme.cream.opacity(0.68))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.86), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var composerPanel: some View {
        VStack(spacing: 10) {
            iOSSubmitTextView(
                text: $draftText,
                selectedRange: $draftSelection,
                measuredHeight: $draftEditorHeight,
                isFocused: $editorIsFocused,
                onSubmit: submit
            )
                .font(.title3)
                .frame(height: editorHeight)
                .padding(8)
                .background(LucyTheme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(LucyTheme.plum.opacity(0.52), lineWidth: 2)
                )

            if showEmotePicker {
                iOSEmotePicker(
                    onClose: {
                        showEmotePicker = false
                    },
                    onSelect: insertEmote
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                commandButtons
            }

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

    private var editorHeight: CGFloat {
        min(max(draftEditorHeight, 76), 150)
    }

    private var commandButtons: some View {
        HStack(spacing: 6) {
            speakButton
            replayButton
            stopButton
            clearQueueButton
            phraseCatalogButton
            emoteMenuButton
        }
        .frame(height: 38)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var speakButton: some View {
        Button(action: submit) {
            Text("Speak")
        }
        .buttonStyle(CommandPillStyle(tint: LucyTheme.hotPink, foreground: .white))
    }

    private var replayButton: some View {
        Button {
            speechQueue.replayLastSpoken()
        } label: {
            Text("Replay")
        }
        .buttonStyle(CommandPillStyle(tint: LucyTheme.plum.opacity(0.22), foreground: LucyTheme.plum))
        .disabled(speechQueue.lastSpokenText == nil)
    }

    private var stopButton: some View {
        Button {
            speechQueue.stopCurrent()
        } label: {
            Text("Stop")
        }
        .buttonStyle(CommandPillStyle(tint: LucyTheme.plum.opacity(0.22), foreground: LucyTheme.plum))
    }

    private var clearQueueButton: some View {
        Button {
            speechQueue.clearQueue()
        } label: {
            Text("Clear")
        }
        .buttonStyle(CommandPillStyle(tint: LucyTheme.plum.opacity(0.22), foreground: LucyTheme.plum))
    }

    private var phraseCatalogButton: some View {
        Button {
            editorIsFocused = false
            showPhraseCatalog = true
        } label: {
            Text("Phrases")
        }
        .buttonStyle(CommandPillStyle(tint: LucyTheme.plum.opacity(0.22), foreground: LucyTheme.plum))
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
        editorIsFocused = true
    }

    private func insertEmote(_ tag: String) {
        insertPhrase("\(tag) ")
        showEmotePicker = false
    }

    private func insertPhrase(_ phrase: String) {
        let insertion = phrase
        let original = draftText as NSString
        let range = clamped(draftSelection, in: original)
        draftText = original.replacingCharacters(in: range, with: insertion)
        draftSelection = NSRange(location: range.location + (insertion as NSString).length, length: 0)
        showPhraseCatalog = false
        editorIsFocused = true
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
    PhraseCatalogTab(
        name: "Quick",
        phrases: [
            PhraseCatalogPhrase(title: "One sec", text: "One sec."),
            PhraseCatalogPhrase(title: "Typing", text: "I'm typing."),
            PhraseCatalogPhrase(title: "Repeat", text: "Could you repeat that?"),
            PhraseCatalogPhrase(title: "Thank you", text: "Thank you.")
        ]
    ),
    PhraseCatalogTab(
        name: "Care",
        phrases: [
            PhraseCatalogPhrase(title: "Water", text: "Could I have some water?"),
            PhraseCatalogPhrase(title: "Break", text: "I need a short break."),
            PhraseCatalogPhrase(title: "Help", text: "I need help with something."),
            PhraseCatalogPhrase(title: "Okay", text: "I'm okay.")
        ]
    ),
    PhraseCatalogTab(
        name: "Meeting",
        phrases: [
            PhraseCatalogPhrase(title: "Give me a second", text: "Can you give me a second?"),
            PhraseCatalogPhrase(title: "Question", text: "I have a question."),
            PhraseCatalogPhrase(title: "Agree", text: "That makes sense to me."),
            PhraseCatalogPhrase(title: "Come back", text: "Can we come back to that?")
        ]
    )
]

private struct CommandPillStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    var tint: Color
    var foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .foregroundStyle(foreground.opacity(isEnabled ? 1 : 0.5))
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .frame(maxWidth: .infinity, minHeight: 34)
            .padding(.horizontal, 4)
            .background(tint.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(Capsule())
            .opacity(isEnabled ? 1 : 0.62)
    }
}

private struct iOSPhraseCatalogView: View {
    let items: [iOSSpeechQueueItem]
    var onClose: () -> Void
    var onSelectPhrase: (String) -> Void

    @State private var selectedTabName = starterPhraseCatalogTabs.first?.name ?? "Quick"

    private var tabNames: [String] {
        starterPhraseCatalogTabs.map(\.name) + ["History"]
    }

    private var historyItems: [iOSSpeechQueueItem] {
        Array(items.reversed())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LucyTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    Picker("Catalog", selection: $selectedTabName) {
                        ForEach(tabNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.segmented)

                    catalogBody
                }
                .padding()
            }
            .navigationTitle("Phrases")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", action: onClose)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(LucyTheme.plum)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var catalogBody: some View {
        if selectedTabName == "History" {
            historyContent
        } else if let tab = starterPhraseCatalogTabs.first(where: { $0.name == selectedTabName }) {
            phraseContent(for: tab)
        }
    }

    private func phraseContent(for tab: PhraseCatalogTab) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if tab.phrases.isEmpty {
                    emptyState("No phrases yet.")
                } else {
                    ForEach(tab.phrases) { phrase in
                        phraseRow(title: phrase.title, detail: phrase.text) {
                            onSelectPhrase(phrase.text)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var historyContent: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if historyItems.isEmpty {
                    emptyState("No history yet.")
                } else {
                    ForEach(historyItems) { item in
                        phraseRow(title: item.text, detail: item.state.rawValue) {
                            onSelectPhrase(item.text)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func phraseRow(title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(LucyTheme.plum)
                    .lineLimit(2)
                if detail != title {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(LucyTheme.plum.opacity(0.62))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.white.opacity(0.42))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(LucyTheme.hotPink.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(.body.weight(.medium))
            .foregroundStyle(LucyTheme.plum.opacity(0.62))
            .frame(maxWidth: .infinity, minHeight: 180)
    }
}

private struct EmoteButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Emote")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .frame(maxWidth: .infinity, minHeight: 34)
                .padding(.horizontal, 4)
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
