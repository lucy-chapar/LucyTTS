import Foundation

struct TTSConfiguration: Equatable {
    var referenceID: String
    var model: String
    var speed: Double
    var volume: Double
    var format: String
    var latency: String
    var voiceStyleCue: String
}

enum FishAudioError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case emptyAudio
    case requestFailed(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing Fish Audio API key."
        case .invalidURL:
            return "Fish Audio API URL is invalid."
        case .invalidResponse:
            return "Fish Audio returned an invalid response."
        case .emptyAudio:
            return "Fish Audio returned an empty audio file."
        case .requestFailed(let code, let message):
            return "Fish Audio request failed (\(code)): \(message)"
        }
    }
}

final class FishAudioClient {
    private let endpoint = URL(string: "https://api.fish.audio/v1/tts")
    private let modelEndpoint = URL(string: "https://api.fish.audio/model")
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func synthesize(text: String, apiKey: String, configuration: TTSConfiguration) async throws -> Data {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw FishAudioError.missingAPIKey }
        guard let endpoint else { throw FishAudioError.invalidURL }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/msgpack", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.model, forHTTPHeaderField: "model")
        request.timeoutInterval = 60

        var payload: [String: MsgpackValue] = [
            "text": .string(Self.textWithStyleCue(text, cue: configuration.voiceStyleCue)),
            "reference_id": .string(configuration.referenceID),
            "format": .string(configuration.format),
            "latency": .string(configuration.latency),
            "prosody": .map([
                "speed": .double(configuration.speed),
                "volume": .double(configuration.volume)
            ])
        ]
        if configuration.format == "mp3" {
            payload["mp3_bitrate"] = .int(128)
        }
        request.httpBody = MsgpackEncoder.encode(.map(payload))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FishAudioError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = Self.briefErrorMessage(from: data)
            throw FishAudioError.requestFailed(httpResponse.statusCode, message)
        }
        guard !data.isEmpty else { throw FishAudioError.emptyAudio }
        return data
    }

    func testAPIKey(apiKey: String, configuration: TTSConfiguration) async throws {
        _ = try await synthesize(
            text: "Fish Audio key test.",
            apiKey: apiKey,
            configuration: configuration
        )
    }

    func fetchVoiceModel(id: String, apiKey: String) async throws -> FishVoiceModel {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw FishAudioError.missingAPIKey }
        guard let modelEndpoint, let url = URL(string: modelEndpoint.absoluteString + "/" + id) else {
            throw FishAudioError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        let data = try await jsonData(for: request)
        return try JSONDecoder().decode(FishVoiceModel.self, from: data)
    }

    func listMyVoiceModels(apiKey: String) async throws -> [FishVoiceModel] {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw FishAudioError.missingAPIKey }
        guard let modelEndpoint else { throw FishAudioError.invalidURL }

        var components = URLComponents(url: modelEndpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "self", value: "true"),
            URLQueryItem(name: "page_size", value: "100"),
            URLQueryItem(name: "page_number", value: "1")
        ]
        guard let url = components?.url else { throw FishAudioError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        let data = try await jsonData(for: request)
        return try JSONDecoder().decode(FishVoiceModelListResponse.self, from: data).items
    }

    private func jsonData(for request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FishAudioError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = Self.briefErrorMessage(from: data)
            throw FishAudioError.requestFailed(httpResponse.statusCode, message)
        }
        return data
    }

    private static func briefErrorMessage(from data: Data) -> String {
        guard !data.isEmpty else { return "No response body." }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for key in ["message", "error", "detail"] {
                if let value = json[key] as? String {
                    return value
                }
            }
        }
        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            return String(text.prefix(180))
        }
        return "Unreadable error response."
    }

    private static func textWithStyleCue(_ text: String, cue: String) -> String {
        let trimmedCue = cue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCue.isEmpty else { return text }
        if trimmedCue.hasPrefix("[") {
            return "\(trimmedCue) \(text)"
        }
        return "[\(trimmedCue)] \(text)"
    }
}

struct FishVoiceModel: Decodable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case description
    }
}

private struct FishVoiceModelListResponse: Decodable {
    let items: [FishVoiceModel]
}
