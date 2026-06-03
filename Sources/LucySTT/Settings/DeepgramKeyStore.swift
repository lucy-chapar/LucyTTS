import Foundation
import Security

enum KeychainError: LocalizedError {
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let status):
            if let message = SecCopyErrorMessageString(status, nil) as String? {
                return message
            }
            return "Keychain error \(status)."
        }
    }
}

final class DeepgramKeychainService {
    static let shared = DeepgramKeychainService()

    private let service = "LucySTT.Deepgram"
    private let account = "DeepgramAPIKey"

    func saveAPIKey(_ apiKey: String) throws {
        let data = Data(apiKey.utf8)
        let query = baseQuery()
        let attributes: [String: Any] = [kSecValueData as String: data]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError.unexpectedStatus(addStatus) }
            return
        }
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
    }

    func readAPIKey() throws -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
        guard let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

@MainActor
final class DeepgramKeyStore: ObservableObject {
    @Published private(set) var maskedKey: String?
    @Published private(set) var hasKey = false
    @Published var lastError: String?

    private let keychain: DeepgramKeychainService
    private var cachedKey: String?

    init(keychain: DeepgramKeychainService = .shared) {
        self.keychain = keychain
        refresh()
    }

    func refresh() {
        lastError = nil
        if let env = environmentKey {
            maskedKey = "Environment variable"
            hasKey = true
            cachedKey = env
            return
        }
        if let saved = try? keychain.readAPIKey(), !saved.isEmpty {
            maskedKey = Self.mask(saved)
            hasKey = true
            cachedKey = saved
            return
        }
        maskedKey = nil
        hasKey = false
        cachedKey = nil
    }

    func currentAPIKey() throws -> String {
        if let cachedKey, !cachedKey.isEmpty { return cachedKey }
        if let saved = try keychain.readAPIKey(), !saved.isEmpty {
            cachedKey = saved
            hasKey = true
            maskedKey = Self.mask(saved)
            return saved
        }
        if let env = environmentKey { return env }
        throw DeepgramASRError.missingAPIKey
    }

    func saveAPIKey(_ key: String) {
        lastError = nil
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            lastError = "API key cannot be empty."
            return
        }
        do {
            try keychain.saveAPIKey(trimmed)
            cachedKey = trimmed
            maskedKey = Self.mask(trimmed)
            hasKey = true
        } catch {
            lastError = error.localizedDescription
        }
    }

    static func mask(_ key: String) -> String {
        let suffix = key.suffix(3)
        return String(repeating: "*", count: max(8, min(12, key.count))) + suffix
    }

    private var environmentKey: String? {
        let env = ProcessInfo.processInfo.environment["DEEPGRAM_API_KEY"] ?? ""
        let trimmed = env.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
