import Foundation

enum APIKeyStatus: Equatable {
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
final class SettingsStore: ObservableObject {
    static let defaultReferenceID = "11a3219f88c346929ecb671d695e5a97"

    @Published var apiKeyStatus: APIKeyStatus = .notConfigured
    @Published private(set) var hasUsableAPIKey: Bool = false
    @Published var voicePresets: [VoicePreset]
    @Published var selectedVoicePresetID: String
    @Published var referenceID: String
    @Published var model: String
    @Published var speed: Double
    @Published var volume: Double
    @Published var outputFormat: String
    @Published var latency: String
    @Published var voiceStyleCue: String
    @Published var selectedOutputDeviceID: String
    @Published var meetingModeEnabled: Bool
    @Published var monitorLocally: Bool
    @Published var checkSpelling: Bool
    @Published var autoCorrectSpelling: Bool
    @Published var checkGrammar: Bool
    @Published var lastSettingsError: String?

    private let defaults: UserDefaults
    private let keychain: KeychainService
    private var cachedAPIKey: String?

    init(defaults: UserDefaults = .standard, keychain: KeychainService = .shared) {
        self.defaults = defaults
        self.keychain = keychain
        let savedReferenceID = defaults.string(forKey: "referenceID") ?? Self.defaultReferenceID
        let loadedVoicePresets = Self.loadVoicePresets(defaults: defaults, fallbackReferenceID: savedReferenceID)
        referenceID = savedReferenceID
        voicePresets = loadedVoicePresets
        selectedVoicePresetID = defaults.string(forKey: "selectedVoicePresetID") ?? loadedVoicePresets.first?.id.uuidString ?? ""
        model = defaults.string(forKey: "model") ?? "s2-pro"
        speed = defaults.object(forKey: "speed") as? Double ?? 1.0
        volume = defaults.object(forKey: "volume") as? Double ?? 0.0
        outputFormat = defaults.string(forKey: "outputFormat") ?? "mp3"
        latency = defaults.string(forKey: "latency") ?? "balanced"
        voiceStyleCue = defaults.string(forKey: "voiceStyleCue") ?? ""
        selectedOutputDeviceID = defaults.string(forKey: "selectedOutputDeviceID") ?? AudioDevice.defaultID
        meetingModeEnabled = defaults.bool(forKey: "meetingModeEnabled")
        monitorLocally = defaults.bool(forKey: "monitorLocally")
        checkSpelling = defaults.object(forKey: "checkSpelling") as? Bool ?? true
        autoCorrectSpelling = defaults.bool(forKey: "autoCorrectSpelling")
        checkGrammar = defaults.bool(forKey: "checkGrammar")
        loadAPIKeyStatus()
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

    var selectedVoicePreset: VoicePreset? {
        voicePresets.first { $0.id.uuidString == selectedVoicePresetID }
    }

    var activeVoiceName: String {
        selectedVoicePreset?.displayName ?? "Default voice"
    }

    private var activeReferenceID: String {
        let selectedReferenceID = selectedVoicePreset?.referenceID.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !selectedReferenceID.isEmpty {
            return selectedReferenceID
        }
        return referenceID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func saveSettings() {
        normalizeSelectedVoice()
        referenceID = activeReferenceID
        defaults.set(encodedVoicePresets(), forKey: "voicePresets")
        defaults.set(selectedVoicePresetID, forKey: "selectedVoicePresetID")
        defaults.set(referenceID, forKey: "referenceID")
        defaults.set(model, forKey: "model")
        defaults.set(speed, forKey: "speed")
        defaults.set(volume, forKey: "volume")
        defaults.set(outputFormat, forKey: "outputFormat")
        defaults.set(latency, forKey: "latency")
        defaults.set(voiceStyleCue, forKey: "voiceStyleCue")
        defaults.set(selectedOutputDeviceID, forKey: "selectedOutputDeviceID")
        defaults.set(meetingModeEnabled, forKey: "meetingModeEnabled")
        defaults.set(monitorLocally, forKey: "monitorLocally")
        defaults.set(checkSpelling, forKey: "checkSpelling")
        defaults.set(autoCorrectSpelling, forKey: "autoCorrectSpelling")
        defaults.set(checkGrammar, forKey: "checkGrammar")
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
            hasUsableAPIKey = true
            cachedAPIKey = trimmed
            defaults.set(true, forKey: "hasSavedAPIKey")
            defaults.set(Self.mask(trimmed), forKey: "apiKeyMasked")
            lastSettingsError = nil
        } catch {
            apiKeyStatus = .failed(reason: error.localizedDescription)
        }
    }

    func replaceAPIKey() {
        do {
            try keychain.deleteAPIKey()
            apiKeyStatus = .notConfigured
            hasUsableAPIKey = hasEnvironmentAPIKey
            cachedAPIKey = nil
            defaults.set(false, forKey: "hasSavedAPIKey")
            defaults.removeObject(forKey: "apiKeyMasked")
        } catch {
            apiKeyStatus = .failed(reason: error.localizedDescription)
        }
    }

    func markKeyTestedSuccessfully(_ key: String? = nil) {
        let masked = key.map(Self.mask)
            ?? cachedAPIKey.map(Self.mask)
            ?? defaults.string(forKey: "apiKeyMasked")
            ?? "Saved key"
        apiKeyStatus = .tested(masked: masked)
        hasUsableAPIKey = true
    }

    func markKeyTestFailed(_ reason: String) {
        apiKeyStatus = .failed(reason: reason)
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

    func currentAPIKey() throws -> String {
        if let cachedAPIKey, !cachedAPIKey.isEmpty {
            return cachedAPIKey
        }
        if let saved = try keychain.readAPIKey(), !saved.isEmpty {
            cachedAPIKey = saved
            defaults.set(true, forKey: "hasSavedAPIKey")
            defaults.set(Self.mask(saved), forKey: "apiKeyMasked")
            hasUsableAPIKey = true
            return saved
        }
        if let trimmed = environmentAPIKey {
            return trimmed
        }
        throw FishAudioError.missingAPIKey
    }

    func loadAPIKeyStatus() {
        if hasEnvironmentAPIKey {
            apiKeyStatus = .saved(masked: "Environment fallback")
            hasUsableAPIKey = true
            return
        }
        if defaults.bool(forKey: "hasSavedAPIKey") {
            apiKeyStatus = .saved(masked: defaults.string(forKey: "apiKeyMasked") ?? "Saved key")
            hasUsableAPIKey = true
            return
        }
        apiKeyStatus = .notConfigured
        hasUsableAPIKey = false
    }

    static func mask(_ key: String) -> String {
        let suffix = key.suffix(3)
        return String(repeating: "*", count: max(8, min(12, key.count))) + suffix
    }

    private var environmentAPIKey: String? {
        let env = ProcessInfo.processInfo.environment["FISH_AUDIO_API_KEY"] ?? ""
        let trimmed = env.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var hasEnvironmentAPIKey: Bool {
        environmentAPIKey != nil
    }

    private func normalizeSelectedVoice() {
        if voicePresets.isEmpty {
            voicePresets = [Self.defaultVoicePreset(fallbackReferenceID: referenceID)]
        }
        if !voicePresets.contains(where: { $0.id.uuidString == selectedVoicePresetID }) {
            selectedVoicePresetID = voicePresets.first?.id.uuidString ?? ""
        }
    }

    private func encodedVoicePresets() -> Data? {
        try? JSONEncoder().encode(voicePresets)
    }

    private static func loadVoicePresets(defaults: UserDefaults, fallbackReferenceID: String) -> [VoicePreset] {
        if let data = defaults.data(forKey: "voicePresets"),
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
