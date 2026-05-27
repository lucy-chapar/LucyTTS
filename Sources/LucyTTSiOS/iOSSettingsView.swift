import SwiftUI
import UIKit

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
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(LucyTheme.background)
            .navigationTitle("Settings")
            .toolbarBackground(LucyTheme.blush.opacity(0.82), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        settingsStore.saveSettings()
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Hide Keyboard") {
                        hideKeyboard()
                    }
                }
            }
        }
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
                    .submitLabel(.done)
                    .onSubmit(hideKeyboard)
            } else {
                SecureField("Fish Audio API key", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit(hideKeyboard)
            }
            Toggle("Show API key", isOn: $showAPIKey)
            HStack {
                Button("Save") {
                    hideKeyboard()
                    settingsStore.saveAPIKey(apiKey)
                    apiKey = ""
                }
                Button(testingKey ? "Testing..." : "Test API key") {
                    hideKeyboard()
                    testAPIKey()
                }
                .disabled(testingKey)
            }
            Button("Replace API key", role: .destructive) {
                hideKeyboard()
                settingsStore.replaceAPIKey()
                apiKey = ""
            }
            Text(settingsStore.apiKeyStatus.label)
                .font(.caption)
                .foregroundStyle(statusColor)
        }
    }

    @ViewBuilder
    private var voiceSection: some View {
        Section {
            Picker("Selected voice", selection: selectedVoiceBinding) {
                ForEach(settingsStore.voicePresets) { preset in
                    Text(preset.displayName).tag(preset.id.uuidString)
                }
            }
            NavigationLink {
                FishVoiceBrowserView(
                    savedReferenceIDs: Set(settingsStore.voicePresets.map { $0.referenceID }),
                    apiKeyProvider: { try settingsStore.currentAPIKey() },
                    onSave: { model in settingsStore.saveFishVoiceModel(model) },
                    onUse: { model in settingsStore.useFishVoiceModel(model) }
                )
            } label: {
                Label("Browse Fish voices", systemImage: "magnifyingglass")
            }
            .disabled(!settingsStore.hasUsableAPIKey)
        } header: {
            Text("Voice")
        } footer: {
            if !settingsStore.hasUsableAPIKey {
                Text("Save a Fish Audio API key above to browse voices.")
            }
        }

        Section("Advanced") {
            Button {
                hideKeyboard()
                _ = settingsStore.addVoicePreset()
            } label: {
                Label("Add voice by reference ID", systemImage: "plus")
            }
            Button {
                hideKeyboard()
                importFishVoices()
            } label: {
                Label(loadingVoices ? "Refreshing…" : "Refresh my Fish voices", systemImage: "arrow.clockwise")
            }
            .disabled(loadingVoices || !settingsStore.hasUsableAPIKey)
            Button {
                hideKeyboard()
                fetchFishNames()
            } label: {
                Label(loadingVoices ? "Refreshing…" : "Refresh voice names", systemImage: "text.badge.checkmark")
            }
            .disabled(loadingVoices || !settingsStore.hasUsableAPIKey)
            if let voiceFetchMessage {
                Text(voiceFetchMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        if let preset = settingsStore.selectedVoicePreset {
            iOSVoicePresetEditor(
                preset: preset,
                isSelected: settingsStore.selectedVoicePresetID == preset.id.uuidString,
                canRemove: settingsStore.voicePresets.count > 1,
                onSave: { settingsStore.updateVoicePreset($0) },
                onUse: { id in settingsStore.useVoicePreset(id: id) },
                onRemove: { id in settingsStore.removeVoicePreset(id: id) }
            )
            .id(preset.id)
        }
    }

    private var tuningSection: some View {
        Section("Tuning") {
            TextField("Model", text: $settingsStore.model)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit(hideKeyboard)
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
                .submitLabel(.done)
                .onSubmit(hideKeyboard)
            HStack {
                Button("Soft feminine") {
                    hideKeyboard()
                    settingsStore.voiceStyleCue = "speaks in a soft, warm, feminine tone"
                }
                Button("Bright feminine") {
                    hideKeyboard()
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

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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

private struct iOSVoicePresetEditor: View {
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
        Section("Selected Voice Details") {
            TextField("Name", text: $name)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .onSubmit(saveAndDismissKeyboard)

            TextField("Reference ID", text: $referenceID)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.none)
                .font(.system(.body, design: .monospaced))
                .submitLabel(.done)
                .onSubmit(saveAndDismissKeyboard)

            TextField("Notes", text: $notes)
                .submitLabel(.done)
                .onSubmit(saveAndDismissKeyboard)

            Button("Save voice") {
                saveAndDismissKeyboard()
            }

            Button(isSelected ? "Selected" : "Use this voice") {
                saveAndDismissKeyboard()
                onUse(preset.id)
            }
            .disabled(isSelected)

            Button("Remove voice", role: .destructive) {
                hideKeyboard()
                onRemove(preset.id)
            }
            .disabled(!canRemove)
        }
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

    private func saveAndDismissKeyboard() {
        saveIfChanged()
        hideKeyboard()
    }

    private func saveIfChanged() {
        if hasChanges {
            onSave(editedPreset)
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
