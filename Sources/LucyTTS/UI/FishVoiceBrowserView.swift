import SwiftUI

@MainActor
final class FishVoiceBrowserViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var sortBy: FishVoiceSort = .score
    @Published var language: String = "any"

    @Published private(set) var discoveryItems: [FishVoiceModel] = []
    @Published private(set) var searchItems: [FishVoiceModel] = []
    @Published private(set) var isInitialLoading: Bool = false
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var isPaginating: Bool = false
    @Published private(set) var hasMore: Bool = true
    @Published private(set) var total: Int?
    @Published private(set) var errorMessage: String?

    var displayItems: [FishVoiceModel] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return discoveryItems
        }
        let serverIDs = Set(searchItems.map(\.id))
        let localMatches = discoveryItems.filter { model in
            !serverIDs.contains(model.id) && Self.matchesLocally(model, query: trimmed)
        }
        return searchItems + localMatches
    }

    var isQueryActive: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let client: FishAudioClient
    private let apiKeyProvider: () throws -> String

    private var discoveryPage = 0
    private var searchRequestID = 0
    private var debounceTask: Task<Void, Never>?

    private var languageFilter: String? {
        language == "any" ? nil : language
    }

    init(
        client: FishAudioClient = FishAudioClient(),
        apiKeyProvider: @escaping () throws -> String
    ) {
        self.client = client
        self.apiKeyProvider = apiKeyProvider
    }

    func onAppear() {
        guard discoveryItems.isEmpty, !isInitialLoading else { return }
        Task { await loadInitialDiscovery() }
    }

    func refresh() async {
        debounceTask?.cancel()
        searchRequestID += 1
        discoveryItems = []
        searchItems = []
        discoveryPage = 0
        hasMore = true
        errorMessage = nil
        await loadInitialDiscovery()
        if isQueryActive {
            await performSearch()
        }
    }

    func filterChanged() {
        Task { await refresh() }
    }

    func queryChanged() {
        debounceTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            searchItems = []
            return
        }
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            await self?.performSearch()
        }
    }

    func clearQuery() {
        query = ""
        searchItems = []
        debounceTask?.cancel()
    }

    func loadMoreIfNeeded(current item: FishVoiceModel) {
        guard !isQueryActive, hasMore, !isPaginating else { return }
        guard let index = discoveryItems.firstIndex(where: { $0.id == item.id }) else { return }
        guard index >= discoveryItems.count - 4 else { return }
        Task { await loadNextDiscoveryPage() }
    }

    private func loadInitialDiscovery() async {
        isInitialLoading = true
        defer { isInitialLoading = false }
        errorMessage = nil
        do {
            let key = try apiKeyProvider()
            let page = try await client.listVoiceModels(
                apiKey: key,
                selfOnly: false,
                pageNumber: 1,
                pageSize: 30,
                language: languageFilter,
                sortBy: sortBy
            )
            discoveryItems = page.items
            discoveryPage = 1
            total = page.total
            hasMore = page.hasMore ?? (page.items.count >= 30)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadNextDiscoveryPage() async {
        guard !isPaginating, hasMore else { return }
        isPaginating = true
        defer { isPaginating = false }
        do {
            let key = try apiKeyProvider()
            let nextPage = discoveryPage + 1
            let page = try await client.listVoiceModels(
                apiKey: key,
                selfOnly: false,
                pageNumber: nextPage,
                pageSize: 30,
                language: languageFilter,
                sortBy: sortBy
            )
            let newItems = page.items.filter { incoming in
                !discoveryItems.contains { $0.id == incoming.id }
            }
            discoveryItems.append(contentsOf: newItems)
            discoveryPage = nextPage
            if let serverHasMore = page.hasMore {
                hasMore = serverHasMore
            } else {
                hasMore = !newItems.isEmpty
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func performSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        searchRequestID += 1
        let requestID = searchRequestID
        isSearching = true
        do {
            let key = try apiKeyProvider()
            let page = try await client.listVoiceModels(
                apiKey: key,
                selfOnly: false,
                pageNumber: 1,
                pageSize: 30,
                title: trimmed,
                language: languageFilter,
                sortBy: sortBy
            )
            guard requestID == searchRequestID else { return }
            searchItems = page.items
            isSearching = false
        } catch {
            guard requestID == searchRequestID else { return }
            errorMessage = error.localizedDescription
            isSearching = false
        }
    }

    private static func matchesLocally(_ model: FishVoiceModel, query: String) -> Bool {
        let tokens = query
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return true }
        let haystack = [
            model.title,
            model.description ?? "",
            model.authorName ?? "",
            (model.tags ?? []).joined(separator: " "),
            (model.languages ?? []).joined(separator: " ")
        ]
        .joined(separator: " ")
        .folding(options: .diacriticInsensitive, locale: .current)
        .lowercased()
        return tokens.allSatisfy { haystack.contains($0) }
    }
}

struct FishVoiceBrowserView: View {
    @StateObject private var viewModel: FishVoiceBrowserViewModel
    @StateObject private var samplePlayer = VoiceSamplePlayer()
    @State private var savedReferenceIDs: Set<String>
    @FocusState private var searchFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private let onSave: (FishVoiceModel) -> Void
    private let onUse: (FishVoiceModel) -> Void

    init(
        savedReferenceIDs: Set<String>,
        apiKeyProvider: @escaping () throws -> String,
        onSave: @escaping (FishVoiceModel) -> Void,
        onUse: @escaping (FishVoiceModel) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: FishVoiceBrowserViewModel(apiKeyProvider: apiKeyProvider))
        _savedReferenceIDs = State(initialValue: savedReferenceIDs)
        self.onSave = onSave
        self.onUse = onUse
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .navigationTitle("Browse Fish Voices")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    samplePlayer.stop()
                    dismiss()
                }
            }
            #endif
        }
        .onAppear {
            viewModel.onAppear()
            searchFieldFocused = true
        }
        .onDisappear {
            samplePlayer.stop()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            searchField
            filterRow
        }
        .padding()
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search Fish Discovery…", text: $viewModel.query)
                .textFieldStyle(.plain)
                .focused($searchFieldFocused)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                #endif
                .onChange(of: viewModel.query) { _ in
                    viewModel.queryChanged()
                }
            if viewModel.isSearching {
                ProgressView()
                    .controlSize(.small)
            }
            if !viewModel.query.isEmpty {
                Button {
                    viewModel.clearQuery()
                    searchFieldFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(searchFieldBackgroundColor)
        )
    }

    private var filterRow: some View {
        HStack(spacing: 12) {
            Menu {
                Picker("Sort", selection: $viewModel.sortBy) {
                    ForEach(FishVoiceSort.allCases) { sort in
                        Text(sort.label).tag(sort)
                    }
                }
            } label: {
                Label("Sort: \(viewModel.sortBy.label)", systemImage: "arrow.up.arrow.down")
            }
            .onChange(of: viewModel.sortBy) { _ in viewModel.filterChanged() }

            Menu {
                Picker("Language", selection: $viewModel.language) {
                    Text("Any language").tag("any")
                    Text("English").tag("en")
                    Text("Chinese").tag("zh")
                    Text("Japanese").tag("ja")
                    Text("Korean").tag("ko")
                    Text("Spanish").tag("es")
                    Text("French").tag("fr")
                    Text("German").tag("de")
                    Text("Portuguese").tag("pt")
                    Text("Italian").tag("it")
                }
            } label: {
                Label("Language: \(languageDisplayName)", systemImage: "globe")
            }
            .onChange(of: viewModel.language) { _ in viewModel.filterChanged() }

            Spacer()

            if let total = viewModel.total {
                Text("\(total) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isInitialLoading && viewModel.displayItems.isEmpty {
            loadingState
        } else if let error = viewModel.errorMessage, viewModel.displayItems.isEmpty {
            errorState(message: error)
        } else if viewModel.displayItems.isEmpty {
            emptyState
        } else {
            voiceList
        }
    }

    private var voiceList: some View {
        List {
            if let error = viewModel.errorMessage, !viewModel.displayItems.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            ForEach(viewModel.displayItems) { model in
                FishVoiceRow(
                    model: model,
                    isSaved: savedReferenceIDs.contains(model.id),
                    currentSampleURL: samplePlayer.nowPlaying,
                    sampleLoading: samplePlayer.isLoading,
                    onPlaySample: { url in samplePlayer.toggle(url: url) },
                    onSave: {
                        onSave(model)
                        savedReferenceIDs.insert(model.id)
                    },
                    onUse: {
                        samplePlayer.stop()
                        onUse(model)
                        savedReferenceIDs.insert(model.id)
                        dismiss()
                    }
                )
                .onAppear {
                    viewModel.loadMoreIfNeeded(current: model)
                }
            }
            if viewModel.isPaginating {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        #if os(macOS)
        .listStyle(.inset)
        #else
        .listStyle(.plain)
        #endif
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading Fish Discovery…")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(viewModel.isQueryActive ? "No matches in Discovery yet." : "No voices loaded.")
                .foregroundStyle(.secondary)
            if viewModel.isQueryActive {
                Button("Show all Discovery voices") {
                    viewModel.clearQuery()
                    searchFieldFocused = true
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Reload") {
                    Task { await viewModel.refresh() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Couldn’t load Fish voices")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Try again") {
                Task { await viewModel.refresh() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var languageDisplayName: String {
        switch viewModel.language {
        case "any": return "Any"
        case "en": return "English"
        case "zh": return "Chinese"
        case "ja": return "Japanese"
        case "ko": return "Korean"
        case "es": return "Spanish"
        case "fr": return "French"
        case "de": return "German"
        case "pt": return "Portuguese"
        case "it": return "Italian"
        default: return viewModel.language.uppercased()
        }
    }

    private var searchFieldBackgroundColor: Color {
        #if os(macOS)
        return Color(nsColor: .textBackgroundColor)
        #else
        return Color(.secondarySystemBackground)
        #endif
    }
}

private struct FishVoiceRow: View {
    let model: FishVoiceModel
    let isSaved: Bool
    let currentSampleURL: URL?
    let sampleLoading: Bool
    let onPlaySample: (URL) -> Void
    let onSave: () -> Void
    let onUse: () -> Void

    @State private var didSave: Bool = false

    private var effectivelySaved: Bool { isSaved || didSave }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(model.title.isEmpty ? "Untitled voice" : model.title)
                    .font(.headline)
                    .lineLimit(2)
                if let author = model.authorName {
                    Text("· \(author)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if effectivelySaved {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            if let description = model.description?.trimmingCharacters(in: .whitespacesAndNewlines), !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            if let tags = model.tags, !tags.isEmpty {
                tagChips(tags: tags)
            }
            HStack(spacing: 8) {
                sampleButtons
                Spacer()
                Button {
                    onSave()
                    didSave = true
                } label: {
                    Label(effectivelySaved ? "Saved" : "Save", systemImage: effectivelySaved ? "checkmark" : "tray.and.arrow.down")
                }
                .buttonStyle(.bordered)
                .disabled(effectivelySaved)

                Button {
                    onUse()
                } label: {
                    Label("Use", systemImage: "play.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var sampleButtons: some View {
        if let samples = model.samples?.prefix(2), !samples.isEmpty {
            HStack(spacing: 6) {
                ForEach(Array(samples.enumerated()), id: \.offset) { offset, sample in
                    let isThis = currentSampleURL == sample.audio
                    Button {
                        onPlaySample(sample.audio)
                    } label: {
                        HStack(spacing: 4) {
                            if isThis && sampleLoading {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: isThis ? "stop.fill" : "play.fill")
                            }
                            Text(sampleLabel(for: sample, index: offset, total: samples.count))
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func sampleLabel(for sample: FishVoiceSample, index: Int, total: Int) -> String {
        if let title = sample.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }
        return total > 1 ? "Sample \(index + 1)" : "Sample"
    }

    private func tagChips(tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tags.prefix(10), id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.gray.opacity(0.15)))
                }
            }
        }
    }
}
