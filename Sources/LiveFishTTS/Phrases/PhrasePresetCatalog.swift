import Combine
import Foundation

struct PhrasePreset: Codable, Identifiable, Equatable {
    var id: String
    var text: String
}

struct PhrasePresetCategory: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var phrases: [PhrasePreset]
}

struct PhrasePresetCatalog: Codable, Equatable {
    var schemaVersion: Int
    var updatedAt: Date
    var categories: [PhrasePresetCategory]

    init(schemaVersion: Int = 1, updatedAt: Date = Date(), categories: [PhrasePresetCategory]) {
        self.schemaVersion = schemaVersion
        self.updatedAt = updatedAt
        self.categories = categories
    }
}

@MainActor
final class PhrasePresetStore: ObservableObject {
    @Published private(set) var catalog: PhrasePresetCatalog

    private let defaults: UserDefaults
    private let storageKey = "PhrasePresetCatalog.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let savedCatalog = try? JSONDecoder().decode(PhrasePresetCatalog.self, from: data),
           !savedCatalog.categories.isEmpty {
            catalog = Self.mergedCatalog(savedCatalog)
        } else {
            catalog = .defaultCatalog
        }
    }

    func replaceCatalog(_ newCatalog: PhrasePresetCatalog) {
        catalog = Self.mergedCatalog(newCatalog)
        save()
    }

    func resetToDefaults() {
        catalog = .defaultCatalog
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(catalog) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private static func mergedCatalog(_ savedCatalog: PhrasePresetCatalog) -> PhrasePresetCatalog {
        var mergedCategories = savedCatalog.categories
        let savedIDs = Set(savedCatalog.categories.map(\.id))
        for category in PhrasePresetCatalog.defaultCatalog.categories where !savedIDs.contains(category.id) {
            mergedCategories.append(category)
        }
        return PhrasePresetCatalog(
            schemaVersion: max(savedCatalog.schemaVersion, PhrasePresetCatalog.defaultCatalog.schemaVersion),
            updatedAt: savedCatalog.updatedAt,
            categories: mergedCategories
        )
    }
}

extension PhrasePresetCatalog {
    static let defaultCatalog = PhrasePresetCatalog(categories: [
        PhrasePresetCategory(
            id: "always_useful",
            name: "Always Useful",
            phrases: [
                PhrasePreset(id: "always_useful_001", text: "Yes."),
                PhrasePreset(id: "always_useful_002", text: "No."),
                PhrasePreset(id: "always_useful_003", text: "Maybe."),
                PhrasePreset(id: "always_useful_004", text: "One second."),
                PhrasePreset(id: "always_useful_005", text: "Give me a sec."),
                PhrasePreset(id: "always_useful_006", text: "I’m thinking."),
                PhrasePreset(id: "always_useful_007", text: "I’m listening."),
                PhrasePreset(id: "always_useful_008", text: "I understand."),
                PhrasePreset(id: "always_useful_009", text: "Can you say that again?"),
                PhrasePreset(id: "always_useful_010", text: "Can you slow down a little?"),
                PhrasePreset(id: "always_useful_011", text: "I need the short version."),
                PhrasePreset(id: "always_useful_012", text: "I’m not ignoring you. I’m typing."),
                PhrasePreset(id: "always_useful_013", text: "Thank you for being patient with me."),
                PhrasePreset(id: "always_useful_014", text: "I’m okay. I just need quiet.")
            ]
        ),
        PhrasePresetCategory(
            id: "why_im_using_this",
            name: "Why I’m Using This",
            phrases: [
                PhrasePreset(id: "why_im_using_this_001", text: "Hi, I’m Lucy. I can hear you. I just can’t talk right now."),
                PhrasePreset(id: "why_im_using_this_002", text: "I’m recovering from vocal surgery, so I’m using text-to-speech."),
                PhrasePreset(id: "why_im_using_this_003", text: "I’m on voice rest, so I need to use this app to talk."),
                PhrasePreset(id: "why_im_using_this_004", text: "You can speak normally. I can hear you."),
                PhrasePreset(id: "why_im_using_this_005", text: "Please don’t ask me to whisper. Whispering can still strain my voice."),
                PhrasePreset(id: "why_im_using_this_006", text: "I may take a few extra seconds to answer because I’m typing."),
                PhrasePreset(id: "why_im_using_this_007", text: "Please keep going. I’m following you.")
            ]
        ),
        PhrasePresetCategory(
            id: "public_customer_service",
            name: "Public / Customer Service",
            phrases: [
                PhrasePreset(id: "public_customer_service_001", text: "Hi, I need help with something, and I’m using text-to-speech because I can’t talk right now."),
                PhrasePreset(id: "public_customer_service_002", text: "Could you please help me with this?"),
                PhrasePreset(id: "public_customer_service_003", text: "Could you please show me where to go?"),
                PhrasePreset(id: "public_customer_service_004", text: "Could you please explain the options?"),
                PhrasePreset(id: "public_customer_service_005", text: "Could you please give me a receipt?"),
                PhrasePreset(id: "public_customer_service_006", text: "Could you please text or email that to me?"),
                PhrasePreset(id: "public_customer_service_007", text: "I need a little more detail before I decide."),
                PhrasePreset(id: "public_customer_service_008", text: "I think there may have been a misunderstanding."),
                PhrasePreset(id: "public_customer_service_009", text: "That’s not quite what I meant."),
                PhrasePreset(id: "public_customer_service_010", text: "Thank you, that was helpful.")
            ]
        ),
        PhrasePresetCategory(
            id: "medical_appointments",
            name: "Medical / Appointments",
            phrases: [
                PhrasePreset(id: "medical_appointments_001", text: "I’m recovering from vocal surgery and cannot speak right now."),
                PhrasePreset(id: "medical_appointments_002", text: "I can hear and understand you. Please speak normally."),
                PhrasePreset(id: "medical_appointments_003", text: "I’m having some discomfort, but I’m not in immediate danger."),
                PhrasePreset(id: "medical_appointments_004", text: "I’m having pain and would like advice on what is safe to take."),
                PhrasePreset(id: "medical_appointments_005", text: "I need to know whether this symptom is expected or concerning."),
                PhrasePreset(id: "medical_appointments_006", text: "I need instructions in writing if possible."),
                PhrasePreset(id: "medical_appointments_007", text: "I coughed and I’m worried I may have strained something."),
                PhrasePreset(id: "medical_appointments_008", text: "I accidentally made a sound and I’m worried about whether that matters."),
                PhrasePreset(id: "medical_appointments_009", text: "Please tell me what symptoms mean I should call urgently or go to the ER."),
                PhrasePreset(id: "medical_appointments_010", text: "I’m not able to talk on the phone. Please message me instead."),
                PhrasePreset(id: "medical_appointments_011", text: "Can you please add a note that I am temporarily nonverbal?")
            ]
        ),
        PhrasePresetCategory(
            id: "food_ordering",
            name: "Food / Ordering",
            phrases: [
                PhrasePreset(id: "food_ordering_001", text: "Can I please have a minute to look?"),
                PhrasePreset(id: "food_ordering_002", text: "I’m ready to order."),
                PhrasePreset(id: "food_ordering_003", text: "Could I please get this?"),
                PhrasePreset(id: "food_ordering_004", text: "Could I please get that without cilantro?"),
                PhrasePreset(id: "food_ordering_005", text: "Could I please get that on the side?"),
                PhrasePreset(id: "food_ordering_006", text: "Could I please get a water?"),
                PhrasePreset(id: "food_ordering_007", text: "Could I please get the check?"),
                PhrasePreset(id: "food_ordering_008", text: "Could I get a box for this?"),
                PhrasePreset(id: "food_ordering_009", text: "Is this spicy?"),
                PhrasePreset(id: "food_ordering_010", text: "Does this have dairy?"),
                PhrasePreset(id: "food_ordering_011", text: "Does this contain any meat other than poultry?"),
                PhrasePreset(id: "food_ordering_012", text: "I only eat poultry, so no beef, pork, lamb, or seafood please."),
                PhrasePreset(id: "food_ordering_013", text: "Thank you.")
            ]
        ),
        PhrasePresetCategory(
            id: "driving_travel",
            name: "Driving / Travel",
            phrases: [
                PhrasePreset(id: "driving_travel_001", text: "Can we pull over for a second?"),
                PhrasePreset(id: "driving_travel_002", text: "I need a break from this conversation while we’re driving."),
                PhrasePreset(id: "driving_travel_003", text: "I don’t want to decide this in the car."),
                PhrasePreset(id: "driving_travel_004", text: "Can we just focus on directions right now?"),
                PhrasePreset(id: "driving_travel_005", text: "Can you please slow down a little?"),
                PhrasePreset(id: "driving_travel_006", text: "Can you please give more following distance?"),
                PhrasePreset(id: "driving_travel_007", text: "I’m not criticizing your driving. I’m anxious."),
                PhrasePreset(id: "driving_travel_008", text: "Where are we parking?"),
                PhrasePreset(id: "driving_travel_009", text: "How long will this take?"),
                PhrasePreset(id: "driving_travel_010", text: "Can we go home after this?"),
                PhrasePreset(id: "driving_travel_011", text: "This place is too loud for me right now."),
                PhrasePreset(id: "driving_travel_012", text: "I need a minute somewhere quieter.")
            ]
        ),
        PhrasePresetCategory(
            id: "friends_support",
            name: "Friends / Support",
            phrases: [
                PhrasePreset(id: "friends_support_001", text: "I’m having a hard day."),
                PhrasePreset(id: "friends_support_002", text: "Can you sit with me for a bit?"),
                PhrasePreset(id: "friends_support_003", text: "Can you help me reality-check this?"),
                PhrasePreset(id: "friends_support_004", text: "Can you help me write a message that doesn’t make things worse?"),
                PhrasePreset(id: "friends_support_005", text: "I need company, but I don’t have a lot of social battery."),
                PhrasePreset(id: "friends_support_006", text: "I’m safe, I’m just overwhelmed."),
                PhrasePreset(id: "friends_support_007", text: "I’m not looking for advice yet."),
                PhrasePreset(id: "friends_support_008", text: "I am looking for advice. Please be kind but direct."),
                PhrasePreset(id: "friends_support_009", text: "Thank you for being here."),
                PhrasePreset(id: "friends_support_010", text: "I really needed that.")
            ]
        ),
        PhrasePresetCategory(
            id: "relationship_conflict",
            name: "Relationship / Conflict",
            phrases: [
                PhrasePreset(id: "relationship_conflict_001", text: "I’m overwhelmed and I need a pause."),
                PhrasePreset(id: "relationship_conflict_002", text: "I’m not leaving the conversation. I need a break."),
                PhrasePreset(id: "relationship_conflict_003", text: "I care about you, and I need this to be less intense."),
                PhrasePreset(id: "relationship_conflict_004", text: "I’m not trying to win. I’m trying to understand what’s happening."),
                PhrasePreset(id: "relationship_conflict_005", text: "I need comfort before we try to solve this."),
                PhrasePreset(id: "relationship_conflict_006", text: "I need us to solve the practical problem first."),
                PhrasePreset(id: "relationship_conflict_007", text: "Can you ask what I mean instead of assuming?"),
                PhrasePreset(id: "relationship_conflict_008", text: "That hurt me."),
                PhrasePreset(id: "relationship_conflict_009", text: "That made me feel rejected."),
                PhrasePreset(id: "relationship_conflict_010", text: "I’m not saying you’re bad. I’m saying this hurt me."),
                PhrasePreset(id: "relationship_conflict_011", text: "I want us to be kind even if we’re angry."),
                PhrasePreset(id: "relationship_conflict_012", text: "I can take accountability without taking blame for everything."),
                PhrasePreset(id: "relationship_conflict_013", text: "Can you be specific about what you want me to do differently?"),
                PhrasePreset(id: "relationship_conflict_014", text: "Please don’t make this about whether I’m good or bad."),
                PhrasePreset(id: "relationship_conflict_015", text: "I’m sorry. I got defensive because I felt cornered."),
                PhrasePreset(id: "relationship_conflict_016", text: "I’m sorry. I want to repair this."),
                PhrasePreset(id: "relationship_conflict_017", text: "I need physical space right now, but I still care about you.")
            ]
        ),
        PhrasePresetCategory(
            id: "boundaries_safety",
            name: "Boundaries / Safety",
            phrases: [
                PhrasePreset(id: "boundaries_safety_001", text: "No, thank you."),
                PhrasePreset(id: "boundaries_safety_002", text: "I’m not comfortable with that."),
                PhrasePreset(id: "boundaries_safety_003", text: "I don’t want to discuss that right now."),
                PhrasePreset(id: "boundaries_safety_004", text: "I’m not ready to decide that today."),
                PhrasePreset(id: "boundaries_safety_005", text: "Please don’t pressure me for an answer right now."),
                PhrasePreset(id: "boundaries_safety_006", text: "That’s not a small ask for me."),
                PhrasePreset(id: "boundaries_safety_007", text: "I’m not saying never. I’m saying not like this."),
                PhrasePreset(id: "boundaries_safety_008", text: "I need this conversation to slow down or stop."),
                PhrasePreset(id: "boundaries_safety_009", text: "I’m not okay with being spoken to that way."),
                PhrasePreset(id: "boundaries_safety_010", text: "I need help."),
                PhrasePreset(id: "boundaries_safety_011", text: "I need to leave now."),
                PhrasePreset(id: "boundaries_safety_012", text: "I don’t feel safe here."),
                PhrasePreset(id: "boundaries_safety_013", text: "Please don’t touch me."),
                PhrasePreset(id: "boundaries_safety_014", text: "Please help me get somewhere quiet."),
                PhrasePreset(id: "boundaries_safety_015", text: "Please help me get home safely.")
            ]
        ),
        PhrasePresetCategory(
            id: "work_meetings",
            name: "Work / Meetings",
            phrases: [
                PhrasePreset(id: "work_meetings_001", text: "What decision are we actually trying to make here?"),
                PhrasePreset(id: "work_meetings_002", text: "Who owns this after today?"),
                PhrasePreset(id: "work_meetings_003", text: "What does done look like?"),
                PhrasePreset(id: "work_meetings_004", text: "What is the smallest useful next step?"),
                PhrasePreset(id: "work_meetings_005", text: "Can we separate urgent from important?"),
                PhrasePreset(id: "work_meetings_006", text: "Can we write this down instead of relying on memory?"),
                PhrasePreset(id: "work_meetings_007", text: "I’m not trying to assign blame. I’m trying to make the process clearer."),
                PhrasePreset(id: "work_meetings_008", text: "I think this needs one owner, one deadline, and one place where the answer lives."),
                PhrasePreset(id: "work_meetings_009", text: "I don’t think this needs a meeting unless there is a decision to make."),
                PhrasePreset(id: "work_meetings_010", text: "I can support this, but I need the authority to actually move it forward.")
            ]
        ),
        PhrasePresetCategory(
            id: "big_decisions",
            name: "Big Decisions",
            phrases: [
                PhrasePreset(id: "big_decisions_001", text: "I need to make this decision from safety, not panic."),
                PhrasePreset(id: "big_decisions_002", text: "I don’t want to confuse urgency with clarity."),
                PhrasePreset(id: "big_decisions_003", text: "I need fewer hypotheticals and more concrete next steps."),
                PhrasePreset(id: "big_decisions_004", text: "I need to know what is reversible and what is not."),
                PhrasePreset(id: "big_decisions_005", text: "I don’t need certainty. I need enough clarity to act."),
                PhrasePreset(id: "big_decisions_006", text: "Both things can be true.")
            ]
        ),
        PhrasePresetCategory(
            id: "closers",
            name: "Closers",
            phrases: [
                PhrasePreset(id: "closers_001", text: "That’s all for now."),
                PhrasePreset(id: "closers_002", text: "Thank you for listening."),
                PhrasePreset(id: "closers_003", text: "Thank you for being patient."),
                PhrasePreset(id: "closers_004", text: "I’m going to rest now."),
                PhrasePreset(id: "closers_005", text: "I’m going to stop typing for a bit."),
                PhrasePreset(id: "closers_006", text: "I love you."),
                PhrasePreset(id: "closers_007", text: "I appreciate you.")
            ]
        )
    ])
}
