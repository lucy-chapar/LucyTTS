import XCTest
@testable import LucyTTS

/// Tests that exercise SettingsStore logic without touching the real Keychain.
/// Each test gets a private UserDefaults suite so writes don't leak between tests
/// or pollute the host app's standard defaults. We deliberately avoid any call
/// that would reach KeychainService (saveAPIKey, replaceAPIKey, currentAPIKey).
@MainActor
final class SettingsStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "LucyTTSTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testMaskHidesMostOfKeyButKeepsLastThreeCharacters() {
        let masked = SettingsStore.mask("abcdefghij1234567XYZ")
        XCTAssertTrue(masked.hasSuffix("XYZ"))
        XCTAssertTrue(masked.dropLast(3).allSatisfy { $0 == "*" })
        // 8..<=12 asterisks
        XCTAssertGreaterThanOrEqual(masked.count - 3, 8)
        XCTAssertLessThanOrEqual(masked.count - 3, 12)
    }

    func testTTSConfigurationFallsBackToDefaultModelWhenBlank() {
        let store = SettingsStore(defaults: defaults)
        store.model = "   "
        XCTAssertEqual(store.ttsConfiguration.model, "s2-pro")
    }

    func testTTSConfigurationUsesSelectedVoiceReferenceID() {
        let store = SettingsStore(defaults: defaults)
        let preset = store.addVoicePreset()
        var updated = preset
        updated.referenceID = "test-reference-id"
        store.updateVoicePreset(updated)
        store.useVoicePreset(id: updated.id)
        XCTAssertEqual(store.ttsConfiguration.referenceID, "test-reference-id")
    }

    func testAddVoicePresetAppendsAndSelectsNewPreset() {
        let store = SettingsStore(defaults: defaults)
        let startingCount = store.voicePresets.count
        let preset = store.addVoicePreset()
        XCTAssertEqual(store.voicePresets.count, startingCount + 1)
        XCTAssertEqual(store.selectedVoicePresetID, preset.id.uuidString)
    }

    func testRemoveVoicePresetIsNoOpWhenOnlyOneRemains() {
        let store = SettingsStore(defaults: defaults)
        // Default initializer seeds exactly one preset.
        XCTAssertEqual(store.voicePresets.count, 1)
        let onlyPreset = store.voicePresets[0]
        store.removeVoicePreset(id: onlyPreset.id)
        XCTAssertEqual(store.voicePresets.count, 1, "Must keep at least one voice preset")
    }

    func testRemoveVoicePresetNormalizesSelectionWhenSelectedPresetGoesAway() {
        let store = SettingsStore(defaults: defaults)
        let extraPreset = store.addVoicePreset()
        XCTAssertEqual(store.selectedVoicePresetID, extraPreset.id.uuidString)
        store.removeVoicePreset(id: extraPreset.id)
        XCTAssertNotEqual(store.selectedVoicePresetID, extraPreset.id.uuidString)
        XCTAssertTrue(store.voicePresets.contains { $0.id.uuidString == store.selectedVoicePresetID })
    }

    func testVoicePresetsPersistAcrossStoreInstances() {
        do {
            let store = SettingsStore(defaults: defaults)
            let preset = store.addVoicePreset()
            var updated = preset
            updated.name = "Persisted Voice"
            updated.referenceID = "persisted-ref"
            store.updateVoicePreset(updated)
        }
        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertTrue(
            reloaded.voicePresets.contains { $0.name == "Persisted Voice" && $0.referenceID == "persisted-ref" },
            "Voice presets should round-trip through UserDefaults"
        )
    }
}
