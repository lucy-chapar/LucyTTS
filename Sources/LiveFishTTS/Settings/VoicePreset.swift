import Foundation

struct VoicePreset: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var referenceID: String
    var notes: String

    init(id: UUID = UUID(), name: String, referenceID: String, notes: String = "") {
        self.id = id
        self.name = name
        self.referenceID = referenceID
        self.notes = notes
    }

    var displayName: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            return trimmedName
        }
        let trimmedID = referenceID.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedID.count > 8 {
            return "Voice \(trimmedID.suffix(8))"
        }
        return "Untitled voice"
    }
}
