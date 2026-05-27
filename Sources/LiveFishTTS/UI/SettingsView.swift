import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var audioOutput: AudioOutputService
    @EnvironmentObject private var speechQueue: SpeechQueueManager
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey = ""
    @State private var showAPIKey = false
    @State private var testingKey = false
    @State private var loadingVoices = false
    @State private var voiceFetchMessage: String?
    @State private var showVoiceBrowser = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                apiKeySettings
                voiceSettings
                typingSettings
                audioSettings
                doneButton
            }
            .padding()
        }
        .frame(width: 720, height: 700)
        .sheet(isPresented: $showVoiceBrowser) {
            FishVoiceBrowserView(
                savedReferenceIDs: Set(settingsStore.voicePresets.map { $0.referenceID }),
                apiKeyProvider: { try settingsStore.currentAPIKey() },
                onSave: { model in settingsStore.saveFishVoiceModel(model) },
                onUse: { model in settingsStore.useFishVoiceModel(model) }
            )
            .frame(minWidth: 640, minHeight: 560)
        }
        .onChange(of: settingsStore.referenceID) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.voicePresets) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.selectedVoicePresetID) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.model) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.speed) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.volume) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.voiceStyleCue) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.outputFormat) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.latency) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.selectedOutputDeviceID) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.meetingModeEnabled) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.checkSpelling) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.autoCorrectSpelling) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.checkGrammar) { _ in settingsStore.saveSettings() }
    }

    private var apiKeySettings: some View {
        GroupBox("Fish Audio API Key") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if showAPIKey {
                        TextField("Fish Audio API key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("Fish Audio API key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    Toggle("Show", isOn: $showAPIKey)
                        .toggleStyle(.checkbox)
                }
                HStack {
                    Button("Save") {
                        settingsStore.saveAPIKey(apiKey)
                        apiKey = ""
                    }
                    Button(testingKey ? "Testing..." : "Test API key") {
                        testAPIKey()
                    }
                    .disabled(testingKey)
                    Button("Replace API key") {
                        settingsStore.replaceAPIKey()
                        apiKey = ""
                    }
                    Spacer()
                    Text(settingsStore.apiKeyStatus.label)
                        .foregroundStyle(statusColor)
                }
                if case .saved(let masked) = settingsStore.apiKeyStatus {
                    Text(masked)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                if case .tested(let masked) = settingsStore.apiKeyStatus {
                    Text(masked)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var voiceSettings: some View {
        GroupBox("Voice") {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Selected voice", selection: selectedVoiceBinding) {
                    ForEach(settingsStore.voicePresets) { preset in
                        Text(preset.displayName).tag(preset.id.uuidString)
                    }
                }
                HStack {
                    Button("Add voice") {
                        _ = settingsStore.addVoicePreset()
                    }
                    Button("Browse Fish voices…") {
                        showVoiceBrowser = true
                    }
                    .disabled(!settingsStore.hasUsableAPIKey)
                    Button(loadingVoices ? "Loading..." : "Import my Fish voices") {
                        importFishVoices()
                    }
                    .disabled(loadingVoices)
                    Button(loadingVoices ? "Loading..." : "Fetch Fish names") {
                        fetchFishNames()
                    }
                    .disabled(loadingVoices)
                    Spacer()
                    if let voiceFetchMessage {
                        Text(voiceFetchMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let preset = settingsStore.selectedVoicePreset {
                    MacVoicePresetEditor(
                        preset: preset,
                        isSelected: settingsStore.selectedVoicePresetID == preset.id.uuidString,
                        canRemove: settingsStore.voicePresets.count > 1,
                        onSave: { settingsStore.updateVoicePreset($0) },
                        onUse: { id in settingsStore.useVoicePreset(id: id) },
                        onRemove: { id in settingsStore.removeVoicePreset(id: id) }
                    )
                    .id(preset.id)
                }
                voiceTuningSettings
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var voiceTuningSettings: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Model", text: $settingsStore.model)
            HStack {
                Text("Speed")
                Slider(value: $settingsStore.speed, in: 0.5...2.0, step: 0.05)
                Text(settingsStore.speed, format: .number.precision(.fractionLength(2)))
                    .frame(width: 48, alignment: .trailing)
            }
            HStack {
                Text("Volume")
                Slider(value: $settingsStore.volume, in: -20.0...20.0, step: 1.0)
                Text("\(Int(settingsStore.volume)) dB")
                    .frame(width: 48, alignment: .trailing)
            }
            TextField("S2-Pro style cue", text: $settingsStore.voiceStyleCue)
            HStack {
                Button("Soft feminine") {
                    settingsStore.voiceStyleCue = "speaks in a soft, warm, feminine tone"
                }
                Button("Bright feminine") {
                    settingsStore.voiceStyleCue = "speaks in a bright, clear, feminine voice"
                }
                Button("Clear") {
                    settingsStore.voiceStyleCue = ""
                }
            }
            Text("Fish documents speed and volume prosody, plus S2-Pro bracket style cues. Pitch and resonance are not documented API controls.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("Output format", selection: $settingsStore.outputFormat) {
                Text("mp3").tag("mp3")
                Text("wav").tag("wav")
            }
            Picker("Latency", selection: $settingsStore.latency) {
                Text("Balanced").tag("balanced")
                Text("Normal").tag("normal")
            }
        }
    }

    private var typingSettings: some View {
        GroupBox("Typing Assistance") {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Check spelling", isOn: $settingsStore.checkSpelling)
                    .toggleStyle(.checkbox)
                Toggle("Auto-correct spelling", isOn: $settingsStore.autoCorrectSpelling)
                    .toggleStyle(.checkbox)
                Toggle("Check grammar", isOn: $settingsStore.checkGrammar)
                    .toggleStyle(.checkbox)
                Text("Spelling suggestions are available from the standard macOS context menu on underlined words.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var audioSettings: some View {
        GroupBox("Audio Routing") {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Output device", selection: $settingsStore.selectedOutputDeviceID) {
                    ForEach(audioOutput.devices) { device in
                        Text(device.name).tag(device.id)
                    }
                }
                HStack {
                    Toggle("Meeting Mode", isOn: $settingsStore.meetingModeEnabled)
                        .toggleStyle(.switch)
                    Toggle("Monitor locally", isOn: $settingsStore.monitorLocally)
                        .toggleStyle(.checkbox)
                        .disabled(true)
                    Spacer()
                    Button("Refresh devices") {
                        audioOutput.refreshDevices()
                    }
                    Button("Test meeting audio") {
                        speechQueue.testMeetingAudio()
                    }
                }
                if settingsStore.meetingModeEnabled && settingsStore.selectedOutputDeviceID == AudioDevice.defaultID {
                    Text("No virtual audio device selected. Install BlackHole or Loopback to use Meeting Mode.")
                        .foregroundStyle(.orange)
                }
                Text("Output: \(audioOutput.deviceName(for: settingsStore.selectedOutputDeviceID))")
                    .foregroundStyle(.secondary)
                Text("Meeting Mode: \(settingsStore.meetingModeEnabled ? "On" : "Off")")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var doneButton: some View {
        HStack {
            Spacer()
            Button("Done") {
                settingsStore.saveSettings()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var statusColor: Color {
        if case .failed = settingsStore.apiKeyStatus {
            return .red
        }
        if case .tested = settingsStore.apiKeyStatus {
            return .green
        }
        return .secondary
    }

    private var selectedVoiceBinding: Binding<String> {
        Binding(
            get: { settingsStore.selectedVoicePresetID },
            set: { newValue in
                guard let id = UUID(uuidString: newValue) else { return }
                settingsStore.useVoicePreset(id: id)
            }
        )
    }

    private func testAPIKey() {
        testingKey = true
        let keyToTest = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let configuration = settingsStore.ttsConfiguration
        Task {
            do {
                let key = keyToTest.isEmpty ? try settingsStore.currentAPIKey() : keyToTest
                try await FishAudioClient().testAPIKey(apiKey: key, configuration: configuration)
                await MainActor.run {
                    if !keyToTest.isEmpty {
                        settingsStore.saveAPIKey(keyToTest)
                    }
                    settingsStore.markKeyTestedSuccessfully(key)
                    apiKey = ""
                    testingKey = false
                }
            } catch {
                await MainActor.run {
                    settingsStore.markKeyTestFailed(error.localizedDescription)
                    testingKey = false
                }
            }
        }
    }

    private func importFishVoices() {
        loadingVoices = true
        voiceFetchMessage = nil
        Task {
            do {
                let key = try await MainActor.run { try settingsStore.currentAPIKey() }
                let models = try await FishAudioClient().listMyVoiceModels(apiKey: key)
                await MainActor.run {
                    settingsStore.mergeFishVoiceModels(models)
                    voiceFetchMessage = "Imported \(models.count) voice\(models.count == 1 ? "" : "s")."
                    loadingVoices = false
                }
            } catch {
                await MainActor.run {
                    voiceFetchMessage = error.localizedDescription
                    loadingVoices = false
                }
            }
        }
    }

    private func fetchFishNames() {
        loadingVoices = true
        voiceFetchMessage = nil
        let ids = settingsStore.voicePresets
            .map { $0.referenceID.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        Task {
            do {
                let key = try await MainActor.run { try settingsStore.currentAPIKey() }
                var updated = 0
                for id in ids {
                    let model = try await FishAudioClient().fetchVoiceModel(id: id, apiKey: key)
                    await MainActor.run {
                        settingsStore.updateVoicePresetFromFish(model)
                    }
                    updated += 1
                }
                await MainActor.run {
                    voiceFetchMessage = "Updated \(updated) voice\(updated == 1 ? "" : "s")."
                    loadingVoices = false
                }
            } catch {
                await MainActor.run {
                    voiceFetchMessage = error.localizedDescription
                    loadingVoices = false
                }
            }
        }
    }
}

private struct MacVoicePresetEditor: View {
    let preset: VoicePreset
    let isSelected: Bool
    let canRemove: Bool
    let onSave: (VoicePreset) -> Void
    let onUse: (UUID) -> Void
    let onRemove: (UUID) -> Void

    @State private var name: String
    @State private var referenceID: String
    @State private var notes: String

    init(
        preset: VoicePreset,
        isSelected: Bool,
        canRemove: Bool,
        onSave: @escaping (VoicePreset) -> Void,
        onUse: @escaping (UUID) -> Void,
        onRemove: @escaping (UUID) -> Void
    ) {
        self.preset = preset
        self.isSelected = isSelected
        self.canRemove = canRemove
        self.onSave = onSave
        self.onUse = onUse
        self.onRemove = onRemove
        _name = State(initialValue: preset.name)
        _referenceID = State(initialValue: preset.referenceID)
        _notes = State(initialValue: preset.notes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Name", text: $name)
            TextField("Reference ID", text: $referenceID)
                .font(.system(.body, design: .monospaced))
            TextField("Notes", text: $notes)
                .font(.caption)
            HStack {
                Button("Save voice") {
                    saveIfChanged()
                }
                Button(isSelected ? "Selected" : "Use") {
                    saveIfChanged()
                    onUse(preset.id)
                }
                .disabled(isSelected)
                Button("Remove") {
                    onRemove(preset.id)
                }
                .disabled(!canRemove)
            }
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onDisappear {
            saveIfChanged()
        }
    }

    private var editedPreset: VoicePreset {
        VoicePreset(
            id: preset.id,
            name: name,
            referenceID: referenceID.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes
        )
    }

    private var hasChanges: Bool {
        name != preset.name
            || referenceID.trimmingCharacters(in: .whitespacesAndNewlines) != preset.referenceID
            || notes != preset.notes
    }

    private func saveIfChanged() {
        if hasChanges {
            onSave(editedPreset)
        }
    }
}
