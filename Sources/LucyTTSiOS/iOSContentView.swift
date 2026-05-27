import SwiftUI

struct iOSContentView: View {
    @EnvironmentObject private var settingsStore: iOSSettingsStore
    @EnvironmentObject private var speechQueue: iOSSpeechQueueManager
    @StateObject private var phrasePresetStore = PhrasePresetStore()
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
                catalog: phrasePresetStore.catalog,
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
    let catalog: PhrasePresetCatalog
    let items: [iOSSpeechQueueItem]
    var onClose: () -> Void
    var onSelectPhrase: (String) -> Void

    @State private var selectedCategoryID = PhrasePresetCatalog.defaultCatalog.categories.first?.id ?? ""
    @State private var searchText = ""

    private var historyItems: [iOSSpeechQueueItem] {
        Array(items.reversed())
    }

    private var selectedCategory: PhrasePresetCategory? {
        catalog.categories.first { $0.id == selectedCategoryID } ?? catalog.categories.first
    }

    private var normalizedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LucyTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    searchField
                    if normalizedSearch.isEmpty {
                        categoryChips
                    }
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
                            historyRow(item) {
                                onSelectPhrase(item.text)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
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
            .padding(.top, 2)
    }

    private var searchField: some View {
        TextField("Search phrases", text: $searchText)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.body)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.44))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(LucyTheme.hotPink.opacity(0.22), lineWidth: 1)
            )
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(catalog.categories) { category in
                    categoryChip(
                        title: category.name,
                        isSelected: category.id == selectedCategoryID
                    ) {
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
                .padding(.vertical, 8)
                .background(isSelected ? LucyTheme.plum : Color.white.opacity(0.42))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func phraseContent(for category: PhrasePresetCategory) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
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
            .padding(.vertical, 4)
        }
    }

    private var historyContent: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                let history = filteredHistoryItems
                if history.isEmpty {
                    emptyState("No history yet.")
                } else {
                    ForEach(history) { item in
                        historyRow(item) {
                            onSelectPhrase(item.text)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func filteredPhrases(in category: PhrasePresetCategory) -> [PhrasePreset] {
        guard !normalizedSearch.isEmpty else { return category.phrases }
        return category.phrases.filter { matchesSearch($0.text) }
    }

    private var filteredHistoryItems: [iOSSpeechQueueItem] {
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
                .minimumScaleFactor(0.86)
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

    private func historyRow(_ item: iOSSpeechQueueItem, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.text)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(LucyTheme.plum)
                    .lineLimit(3)
                Text(item.state.rawValue)
                    .font(.caption)
                    .foregroundStyle(item.state == .error ? .red : LucyTheme.plum.opacity(0.62))
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
