import Foundation

struct DeepgramUtterance: Equatable {
    let speaker: Int
    let text: String
    let start: Double
    let end: Double
}

enum DeepgramASRError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case emptyTranscript
    case requestFailed(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing Deepgram API key. Add one in Lucy STT for speaker labels."
        case .invalidResponse:
            return "Deepgram returned an invalid response."
        case .emptyTranscript:
            return "Deepgram did not detect any speech in this recording."
        case .requestFailed(let code, let message):
            return "Deepgram request failed (\(code)): \(message)"
        }
    }
}

final class DeepgramASRClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func transcribe(
        audioURL: URL,
        apiKey: String,
        progress: (@Sendable (String) -> Void)? = nil
    ) async throws -> [DeepgramUtterance] {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw DeepgramASRError.missingAPIKey }

        progress?("Transcribing with speaker labels (Deepgram)…")

        let audio = try Data(contentsOf: audioURL)
        guard !audio.isEmpty else { throw DeepgramASRError.emptyTranscript }

        var components = URLComponents(string: "https://api.deepgram.com/v1/listen")!
        components.queryItems = [
            URLQueryItem(name: "model", value: "nova-2"),
            URLQueryItem(name: "diarize", value: "true"),
            URLQueryItem(name: "utterances", value: "true"),
            URLQueryItem(name: "punctuate", value: "true"),
            URLQueryItem(name: "smart_format", value: "true"),
            URLQueryItem(name: "language", value: "en")
        ]
        guard let url = components.url else { throw DeepgramASRError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue(contentType(for: audioURL), forHTTPHeaderField: "Content-Type")
        request.httpBody = audio
        request.timeoutInterval = 900

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeepgramASRError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = Self.briefErrorMessage(from: data)
            throw DeepgramASRError.requestFailed(httpResponse.statusCode, message)
        }

        let utterances = try Self.parseUtterances(from: data)
        guard !utterances.isEmpty else { throw DeepgramASRError.emptyTranscript }
        return utterances
    }

    private func contentType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "mp3": return "audio/mpeg"
        case "wav": return "audio/wav"
        case "flac": return "audio/flac"
        case "ogg": return "audio/ogg"
        default: return "audio/mp4"
        }
    }

    private static func parseUtterances(from data: Data) throws -> [DeepgramUtterance] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [String: Any]
        else {
            throw DeepgramASRError.invalidResponse
        }

        if let utterances = results["utterances"] as? [[String: Any]] {
            return utterances.compactMap { item in
                guard let speaker = item["speaker"] as? Int,
                      let transcript = item["transcript"] as? String
                else { return nil }
                let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return nil }
                let start = item["start"] as? Double ?? 0
                let end = item["end"] as? Double ?? start
                return DeepgramUtterance(speaker: speaker, text: text, start: start, end: end)
            }
        }

        return []
    }

    private static func briefErrorMessage(from data: Data) -> String {
        guard !data.isEmpty else { return "No response body." }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let err = json["err_msg"] as? String { return err }
            if let message = json["message"] as? String { return message }
        }
        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            return String(text.prefix(180))
        }
        return "Unreadable error response."
    }
}

enum PlayTranscriptFormatter {
    static func format(
        utterances: [DeepgramUtterance],
        speakerOneName: String,
        speakerTwoName: String
    ) -> String {
        let sorted = utterances.sorted { $0.start < $1.start }
        var blocks: [String] = []
        var currentSpeaker: Int?
        var currentLines: [String] = []

        for utterance in sorted {
            if utterance.speaker == currentSpeaker {
                currentLines.append(utterance.text)
            } else {
                if let currentSpeaker, !currentLines.isEmpty {
                    blocks.append(formatBlock(
                        speaker: currentSpeaker,
                        lines: currentLines,
                        speakerOneName: speakerOneName,
                        speakerTwoName: speakerTwoName
                    ))
                }
                currentSpeaker = utterance.speaker
                currentLines = [utterance.text]
            }
        }

        if let currentSpeaker, !currentLines.isEmpty {
            blocks.append(formatBlock(
                speaker: currentSpeaker,
                lines: currentLines,
                speakerOneName: speakerOneName,
                speakerTwoName: speakerTwoName
            ))
        }

        return blocks.joined(separator: "\n\n")
    }

    private static func formatBlock(
        speaker: Int,
        lines: [String],
        speakerOneName: String,
        speakerTwoName: String
    ) -> String {
        let label = speakerLabel(for: speaker, one: speakerOneName, two: speakerTwoName)
        let body = lines.joined(separator: " ")
        return "\(label.uppercased())\n\(body)"
    }

    private static func speakerLabel(for index: Int, one: String, two: String) -> String {
        index <= 0 ? one : two
    }
}
