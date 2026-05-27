import XCTest
@testable import LucyTTS

final class VoicePresetTests: XCTestCase {
    func testDisplayNamePrefersTrimmedName() {
        let preset = VoicePreset(name: "  Lucy Default  ", referenceID: "ref-1234567890")
        XCTAssertEqual(preset.displayName, "Lucy Default")
    }

    func testDisplayNameFallsBackToTruncatedReferenceID() {
        let preset = VoicePreset(name: "   ", referenceID: "abcdef0123456789")
        XCTAssertEqual(preset.displayName, "Voice 23456789")
    }

    func testDisplayNameReturnsUntitledForShortIDAndEmptyName() {
        let preset = VoicePreset(name: "", referenceID: "abcd")
        XCTAssertEqual(preset.displayName, "Untitled voice")
    }

    func testCodableRoundTripPreservesAllFields() throws {
        let original = VoicePreset(name: "Lucy", referenceID: "ref-1", notes: "Daily voice")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(VoicePreset.self, from: encoded)
        XCTAssertEqual(decoded, original)
    }
}
