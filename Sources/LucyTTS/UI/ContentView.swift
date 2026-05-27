import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var audioOutput: AudioOutputService
    @EnvironmentObject private var speechQueue: SpeechQueueManager
    @StateObject private var phrasePresetStore = PhrasePresetStore()
    @State private var draftText = ""
    @State private var showSettings = false
    @State private var showEmotePicker = false
    @State private var showPhraseCatalog = false
    @State private var pendingTextInsertion: SubmitTextView.PendingInsertion?

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
                pendingInsertion: $pendingTextInsertion,
                onSubmit: submit
            )
            .background(LucyTheme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(LucyTheme.plum.opacity(0.45), lineWidth: 2)
            )
            .frame(minHeight: 210)

            captionView

            HStack {
                Button("Speak", action: submit)
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
                    .tint(LucyTheme.hotPink)
                Button("Replay") {
                    speechQueue.replayLastSpoken()
                }
                .tint(LucyTheme.plum)
                .disabled(speechQueue.lastSpokenText == nil)
                Button("Stop") {
                    speechQueue.stopCurrent()
                }
                .tint(LucyTheme.plum)
                Button("Clear queue") {
                    speechQueue.clearQueue()
                }
                .tint(LucyTheme.plum)
                Button("Phrases") {
                    showPhraseCatalog = true
                }
                .tint(LucyTheme.plum)
                .popover(isPresented: $showPhraseCatalog, arrowEdge: .bottom) {
                    PhraseCatalogPopover(
                        catalog: phrasePresetStore.catalog,
                        items: speechQueue.items,
                        onClose: {
                            showPhraseCatalog = false
                        },
                        onSelectPhrase: insertPhrase
                    )
                    .frame(width: 520, height: 560)
                }
                EmoteButton {
                    showEmotePicker = true
                }
                .popover(isPresented: $showEmotePicker, arrowEdge: .bottom) {
                    EmotePicker(
                        onClose: {
                            showEmotePicker = false
                        },
                        onSelect: insertEmote
                    )
                    .frame(width: 430)
                }
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

    private var captionView: some View {
        Group {
            if let caption = speechQueue.currentCaptionText {
                Text(caption)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(LucyTheme.cream)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(LucyTheme.plum.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
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

    private func insertEmote(_ tag: String) {
        pendingTextInsertion = SubmitTextView.PendingInsertion(text: "\(tag) ")
        showEmotePicker = false
    }

    private func insertPhrase(_ phrase: String) {
        pendingTextInsertion = SubmitTextView.PendingInsertion(text: phrase)
        showPhraseCatalog = false
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
                .padding(.horizontal, 16)
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

private struct EmotePicker: View {
    var onClose: () -> Void
    var onSelect: (String) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 126), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Emote")
                    .font(.headline)
                    .foregroundStyle(LucyTheme.plum)
                Spacer()
                Button("Close", action: onClose)
                    .buttonStyle(.borderless)
                    .foregroundStyle(LucyTheme.plum)
            }
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(fishEmoteTags, id: \.self) { tag in
                    Button(tag) {
                        onSelect(tag)
                    }
                    .buttonStyle(.bordered)
                    .tint(LucyTheme.hotPink)
                }
            }
        }
        .padding(14)
        .background(LucyTheme.background)
    }
}

private struct PhraseCatalogPopover: View {
    let catalog: PhrasePresetCatalog
    let items: [SpeechQueueItem]
    var onClose: () -> Void
    var onSelectPhrase: (String) -> Void

    @State private var selectedCategoryID = PhrasePresetCatalog.defaultCatalog.categories.first?.id ?? ""
    @State private var searchText = ""

    private var selectedCategory: PhrasePresetCategory? {
        catalog.categories.first { $0.id == selectedCategoryID } ?? catalog.categories.first
    }

    private var normalizedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var historyItems: [SpeechQueueItem] {
        Array(items.reversed())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Phrases")
                    .font(.headline)
                    .foregroundStyle(LucyTheme.plum)
                Spacer()
                Button("Close", action: onClose)
                    .buttonStyle(.borderless)
                    .foregroundStyle(LucyTheme.plum)
            }

            TextField("Search phrases", text: $searchText)
                .textFieldStyle(.roundedBorder)

            if normalizedSearch.isEmpty {
                categoryChips
            }
            catalogBody
        }
        .padding(14)
        .background(LucyTheme.background)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(catalog.categories) { category in
                    categoryChip(title: category.name, isSelected: category.id == selectedCategoryID) {
                        selectedCategoryID = category.id
                    }
                }
                categoryChip(title: "History", isSelected: selectedCategoryID == "history") {
                    selectedCategoryID = "history"
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func categoryChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? LucyTheme.cream : LucyTheme.plum)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? LucyTheme.plum : LucyTheme.cream.opacity(0.72))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var catalogBody: some View {
        if !normalizedSearch.isEmpty {
            searchResultsContent
        } else if selectedCategoryID == "history" {
            historyContent
        } else if let selectedCategory {
            phraseContent(for: selectedCategory)
        } else {
            emptyState("No phrases yet.")
        }
    }

    private var searchResultsContent: some View {
        let groups = searchResultGroups
        let historyMatches = filteredHistoryItems
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if groups.isEmpty && historyMatches.isEmpty {
                    emptyState("No phrases match \u{201C}\(normalizedSearch)\u{201D}.")
                } else {
                    ForEach(groups, id: \.category.id) { group in
                        sectionHeader(group.category.name)
                        ForEach(group.phrases) { phrase in
                            phraseButton(text: phrase.text) {
                                onSelectPhrase(phrase.text)
                            }
                        }
                    }
                    if !historyMatches.isEmpty {
                        sectionHeader("History")
                        ForEach(historyMatches) { item in
                            historyButton(item)
                        }
                    }
                }
            }
        }
    }

    private var searchResultGroups: [(category: PhrasePresetCategory, phrases: [PhrasePreset])] {
        guard !normalizedSearch.isEmpty else { return [] }
        return catalog.categories.compactMap { category in
            let matches = category.phrases.filter { matchesSearch($0.text) }
            if matches.isEmpty { return nil }
            return (category, matches)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(LucyTheme.plum.opacity(0.62))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    private func phraseContent(for category: PhrasePresetCategory) -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                let phrases = filteredPhrases(in: category)
                if phrases.isEmpty {
                    emptyState("No phrases yet.")
                } else {
                    ForEach(phrases) { phrase in
                        phraseButton(text: phrase.text) {
                            onSelectPhrase(phrase.text)
                        }
                    }
                }
            }
        }
    }

    private var historyContent: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                let history = filteredHistoryItems
                if history.isEmpty {
                    emptyState("No history yet.")
                } else {
                    ForEach(history) { item in
                        historyButton(item)
                    }
                }
            }
        }
    }

    private func historyButton(_ item: SpeechQueueItem) -> some View {
        Button {
            onSelectPhrase(item.text)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.text)
                    .font(.body.weight(.semibold))
                    .lineLimit(3)
                Text(item.state.rawValue)
                    .font(.caption)
                    .foregroundStyle(item.state == .error ? .red : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(LucyTheme.cream.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func filteredPhrases(in category: PhrasePresetCategory) -> [PhrasePreset] {
        guard !normalizedSearch.isEmpty else { return category.phrases }
        return category.phrases.filter { matchesSearch($0.text) }
    }

    private var filteredHistoryItems: [SpeechQueueItem] {
        guard !normalizedSearch.isEmpty else { return historyItems }
        return historyItems.filter { matchesSearch($0.text) }
    }

    private func matchesSearch(_ text: String) -> Bool {
        let query = normalizedSearch
        guard !query.isEmpty else { return true }
        let tokens = query
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return true }
        let haystack = text
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
        return tokens.allSatisfy { haystack.contains($0) }
    }

    private func phraseButton(text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.body.weight(.semibold))
                .foregroundStyle(LucyTheme.plum)
                .multilineTextAlignment(.leading)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(LucyTheme.cream.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(LucyTheme.plum.opacity(0.62))
            .frame(maxWidth: .infinity, minHeight: 160)
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
