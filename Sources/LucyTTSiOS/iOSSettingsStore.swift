import Foundation

enum iOSAPIKeyStatus: Equatable {
    case notConfigured
    case saved(masked: String)
    case tested(masked: String)
    case failed(reason: String)

    var label: String {
        switch self {
        case .notConfigured:
            return "Not configured"
        case .saved:
            return "Saved"
        case .tested:
            return "Tested successfully"
        case .failed(let reason):
            return "Test failed: \(reason)"
        }
    }
}

@MainActor
final class iOSSettingsStore: ObservableObject {
    static let defaultReferenceID = "11a3219f88c346929ecb671d695e5a97"

    @Published var apiKeyStatus: iOSAPIKeyStatus = .notConfigured
    @Published private(set) var hasUsableAPIKey = false
    @Published var voicePresets: [VoicePreset]
    @Published var selectedVoicePresetID: String
    @Published var model: String
    @Published var speed: Double
    @Published var volume: Double
    @Published var outputFormat: String
    @Published var latency: String
    @Published var voiceStyleCue: String

    private let defaults: UserDefaults
    private let keychain: KeychainService
    private var cachedAPIKey: String?

    init(defaults: UserDefaults = .standard, keychain: KeychainService = .shared) {
        self.defaults = defaults
        self.keychain = keychain
        let savedReferenceID = defaults.string(forKey: "iOSReferenceID") ?? Self.defaultReferenceID
        let loadedVoicePresets = Self.loadVoicePresets(defaults: defaults, fallbackReferenceID: savedReferenceID)
        voicePresets = loadedVoicePresets
        selectedVoicePresetID = defaults.string(forKey: "iOSSelectedVoicePresetID") ?? loadedVoicePresets.first?.id.uuidString ?? ""
        model = defaults.string(forKey: "iOSModel") ?? "s2-pro"
        speed = defaults.object(forKey: "iOSSpeed") as? Double ?? 1.0
        volume = defaults.object(forKey: "iOSVolume") as? Double ?? 0.0
        outputFormat = defaults.string(forKey: "iOSOutputFormat") ?? "mp3"
        latency = defaults.string(forKey: "iOSLatency") ?? "balanced"
        voiceStyleCue = defaults.string(forKey: "iOSVoiceStyleCue") ?? ""
        loadAPIKeyStatus()
    }

    var selectedVoicePreset: VoicePreset? {
        voicePresets.first { $0.id.uuidString == selectedVoicePresetID }
    }

    var activeVoiceName: String {
        selectedVoicePreset?.displayName ?? "Default voice"
    }

    var ttsConfiguration: TTSConfiguration {
        TTSConfiguration(
            referenceID: activeReferenceID,
            model: model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "s2-pro" : model,
            speed: speed,
            volume: volume,
            format: outputFormat,
            latency: latency,
            voiceStyleCue: voiceStyleCue
        )
    }

    func saveSettings() {
        normalizeSelectedVoice()
        defaults.set(encodedVoicePresets(), forKey: "iOSVoicePresets")
        defaults.set(selectedVoicePresetID, forKey: "iOSSelectedVoicePresetID")
        defaults.set(activeReferenceID, forKey: "iOSReferenceID")
        defaults.set(model, forKey: "iOSModel")
        defaults.set(speed, forKey: "iOSSpeed")
        defaults.set(volume, forKey: "iOSVolume")
        defaults.set(outputFormat, forKey: "iOSOutputFormat")
        defaults.set(latency, forKey: "iOSLatency")
        defaults.set(voiceStyleCue, forKey: "iOSVoiceStyleCue")
    }

    func saveAPIKey(_ apiKey: String) {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            apiKeyStatus = .failed(reason: "API key cannot be empty.")
            return
        }
        do {
            try keychain.saveAPIKey(trimmed)
            apiKeyStatus = .saved(masked: Self.mask(trimmed))
            cachedAPIKey = trimmed
            hasUsableAPIKey = true
            defaults.set(true, forKey: "iOSHasSavedAPIKey")
            defaults.set(Self.mask(trimmed), forKey: "iOSAPIKeyMasked")
        } catch {
            apiKeyStatus = .failed(reason: error.localizedDescription)
        }
    }

    func replaceAPIKey() {
        do {
            try keychain.deleteAPIKey()
            cachedAPIKey = nil
            hasUsableAPIKey = false
            apiKeyStatus = .notConfigured
            defaults.set(false, forKey: "iOSHasSavedAPIKey")
            defaults.removeObject(forKey: "iOSAPIKeyMasked")
        } catch {
            apiKeyStatus = .failed(reason: error.localizedDescription)
        }
    }

    func markKeyTestedSuccessfully(_ key: String? = nil) {
        let masked = key.map(Self.mask)
            ?? cachedAPIKey.map(Self.mask)
            ?? defaults.string(forKey: "iOSAPIKeyMasked")
            ?? "Saved key"
        apiKeyStatus = .tested(masked: masked)
        hasUsableAPIKey = true
    }

    func markKeyTestFailed(_ reason: String) {
        apiKeyStatus = .failed(reason: reason)
    }

    func currentAPIKey() throws -> String {
        if let cachedAPIKey, !cachedAPIKey.isEmpty {
            return cachedAPIKey
        }
        if let saved = try keychain.readAPIKey(), !saved.isEmpty {
            cachedAPIKey = saved
            defaults.set(true, forKey: "iOSHasSavedAPIKey")
            defaults.set(Self.mask(saved), forKey: "iOSAPIKeyMasked")
            hasUsableAPIKey = true
            return saved
        }
        throw FishAudioError.missingAPIKey
    }

    func loadAPIKeyStatus() {
        if defaults.bool(forKey: "iOSHasSavedAPIKey") {
            apiKeyStatus = .saved(masked: defaults.string(forKey: "iOSAPIKeyMasked") ?? "Saved key")
            hasUsableAPIKey = true
            return
        }
        apiKeyStatus = .notConfigured
        hasUsableAPIKey = false
    }

    @discardableResult
    func addVoicePreset() -> VoicePreset {
        let preset = VoicePreset(name: "New voice", referenceID: "")
        var updatedPresets = voicePresets
        updatedPresets.append(preset)
        voicePresets = updatedPresets
        selectedVoicePresetID = preset.id.uuidString
        saveSettings()
        return preset
    }

    func removeVoicePreset(id: UUID) {
        guard voicePresets.count > 1 else { return }
        voicePresets = voicePresets.filter { $0.id != id }
        normalizeSelectedVoice()
        saveSettings()
    }

    func useVoicePreset(id: UUID) {
        selectedVoicePresetID = id.uuidString
        normalizeSelectedVoice()
        saveSettings()
    }

    func updateVoicePreset(_ preset: VoicePreset) {
        guard let index = voicePresets.firstIndex(where: { $0.id == preset.id }) else { return }
        var updatedPresets = voicePresets
        updatedPresets[index] = preset
        voicePresets = updatedPresets
        saveSettings()
    }

    func updateVoicePresetFromFish(_ model: FishVoiceModel) {
        var updatedPresets = voicePresets
        if let index = voicePresets.firstIndex(where: { $0.referenceID == model.id }) {
            updatedPresets[index].name = model.title
            updatedPresets[index].notes = model.description ?? updatedPresets[index].notes
        } else {
            updatedPresets.append(VoicePreset(name: model.title, referenceID: model.id, notes: model.description ?? ""))
        }
        voicePresets = updatedPresets
        normalizeSelectedVoice()
        saveSettings()
    }

    func mergeFishVoiceModels(_ models: [FishVoiceModel]) {
        for model in models {
            updateVoicePresetFromFish(model)
        }
        saveSettings()
    }

    @discardableResult
    func saveFishVoiceModel(_ model: FishVoiceModel) -> UUID {
        let referenceID = model.id.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = Self.notesString(for: model)
        var updatedPresets = voicePresets
        let savedID: UUID
        if let index = updatedPresets.firstIndex(where: { $0.referenceID == referenceID }) {
            savedID = updatedPresets[index].id
            updatedPresets[index].name = model.title
            if !notes.isEmpty {
                updatedPresets[index].notes = notes
            }
        } else {
            let preset = VoicePreset(name: model.title, referenceID: referenceID, notes: notes)
            savedID = preset.id
            updatedPresets.append(preset)
        }
        voicePresets = updatedPresets
        normalizeSelectedVoice()
        saveSettings()
        return savedID
    }

    func useFishVoiceModel(_ model: FishVoiceModel) {
        let id = saveFishVoiceModel(model)
        useVoicePreset(id: id)
    }

    fileprivate static func notesString(for model: FishVoiceModel) -> String {
        var parts: [String] = []
        if let description = model.description?.trimmingCharacters(in: .whitespacesAndNewlines), !description.isEmpty {
            parts.append(description)
        }
        if let tags = model.tags, !tags.isEmpty {
            parts.append("Tags: " + tags.joined(separator: ", "))
        }
        if let languages = model.languages, !languages.isEmpty {
            parts.append("Languages: " + languages.joined(separator: ", "))
        }
        return parts.joined(separator: "\n\n")
    }

    static func mask(_ key: String) -> String {
        let suffix = key.suffix(3)
        return String(repeating: "*", count: max(8, min(12, key.count))) + suffix
    }

    private var activeReferenceID: String {
        let selectedReferenceID = selectedVoicePreset?.referenceID.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return selectedReferenceID.isEmpty ? Self.defaultReferenceID : selectedReferenceID
    }

    private func normalizeSelectedVoice() {
        if voicePresets.isEmpty {
            voicePresets = [Self.defaultVoicePreset(fallbackReferenceID: Self.defaultReferenceID)]
        }
        if !voicePresets.contains(where: { $0.id.uuidString == selectedVoicePresetID }) {
            selectedVoicePresetID = voicePresets.first?.id.uuidString ?? ""
        }
    }

    private func encodedVoicePresets() -> Data? {
        try? JSONEncoder().encode(voicePresets)
    }

    private static func loadVoicePresets(defaults: UserDefaults, fallbackReferenceID: String) -> [VoicePreset] {
        if let data = defaults.data(forKey: "iOSVoicePresets"),
           let presets = try? JSONDecoder().decode([VoicePreset].self, from: data),
           !presets.isEmpty {
            return presets
        }
        return [defaultVoicePreset(fallbackReferenceID: fallbackReferenceID)]
    }

    private static func defaultVoicePreset(fallbackReferenceID: String) -> VoicePreset {
        VoicePreset(
            name: "Default voice",
            referenceID: fallbackReferenceID.isEmpty ? Self.defaultReferenceID : fallbackReferenceID,
            notes: "Saved Fish Audio voice"
        )
    }
}
