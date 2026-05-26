import SwiftUI

struct iOSSettingsView: View {
    @EnvironmentObject private var settingsStore: iOSSettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey = ""
    @State private var showAPIKey = false
    @State private var testingKey = false
    @State private var loadingVoices = false
    @State private var voiceFetchMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                apiKeySection
                voiceSection
                tuningSection
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        settingsStore.saveSettings()
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: settingsStore.voicePresets) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.selectedVoicePresetID) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.model) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.speed) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.volume) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.voiceStyleCue) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.outputFormat) { _ in settingsStore.saveSettings() }
        .onChange(of: settingsStore.latency) { _ in settingsStore.saveSettings() }
    }

    private var apiKeySection: some View {
        Section("Fish Audio API Key") {
            if showAPIKey {
                TextField("Fish Audio API key", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                SecureField("Fish Audio API key", text: $apiKey)
            }
            Toggle("Show API key", isOn: $showAPIKey)
            HStack {
                Button("Save") {
                    settingsStore.saveAPIKey(apiKey)
                    apiKey = ""
                }
                Button(testingKey ? "Testing..." : "Test API key") {
                    testAPIKey()
                }
                .disabled(testingKey)
            }
            Button("Replace API key", role: .destructive) {
                settingsStore.replaceAPIKey()
                apiKey = ""
            }
            Text(settingsStore.apiKeyStatus.label)
                .font(.caption)
                .foregroundStyle(statusColor)
        }
    }

    private var voiceSection: some View {
        Section("Voices") {
            Picker("Selected voice", selection: $settingsStore.selectedVoicePresetID) {
                ForEach(settingsStore.voicePresets) { preset in
                    Text(preset.displayName).tag(preset.id.uuidString)
                }
            }
            Button("Add voice") {
                settingsStore.addVoicePreset()
            }
            Button(loadingVoices ? "Loading..." : "Import my Fish voices") {
                importFishVoices()
            }
            .disabled(loadingVoices)
            Button(loadingVoices ? "Loading..." : "Fetch Fish names") {
                fetchFishNames()
            }
            .disabled(loadingVoices)
            if let voiceFetchMessage {
                Text(voiceFetchMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(settingsStore.voicePresets.indices, id: \.self) { index in
                voicePresetEditor(index: index)
            }
        }
    }

    private var tuningSection: some View {
        Section("Tuning") {
            TextField("Model", text: $settingsStore.model)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
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
            }
            Picker("Output format", selection: $settingsStore.outputFormat) {
                Text("mp3").tag("mp3")
                Text("wav").tag("wav")
            }
            Picker("Latency", selection: $settingsStore.latency) {
                Text("Balanced").tag("balanced")
                Text("Normal").tag("normal")
            }
            Text("iPhone playback uses speaker, wired audio, AirPods, or Bluetooth. iOS cannot provide a same-device virtual microphone for Meet.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func voicePresetEditor(index: Int) -> some View {
        let presetBinding = Binding<VoicePreset>(
            get: { settingsStore.voicePresets[index] },
            set: { settingsStore.voicePresets[index] = $0 }
        )
        let preset = presetBinding.wrappedValue

        return VStack(alignment: .leading, spacing: 8) {
            TextField("Name", text: presetBinding.name)
            TextField("Reference ID", text: presetBinding.referenceID)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Notes", text: presetBinding.notes)
            HStack {
                Button(settingsStore.selectedVoicePresetID == preset.id.uuidString ? "Selected" : "Use") {
                    settingsStore.useVoicePreset(id: preset.id)
                }
                .disabled(settingsStore.selectedVoicePresetID == preset.id.uuidString)
                Button("Remove", role: .destructive) {
                    settingsStore.removeVoicePreset(id: preset.id)
                }
                .disabled(settingsStore.voicePresets.count <= 1)
            }
        }
        .padding(.vertical, 6)
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
