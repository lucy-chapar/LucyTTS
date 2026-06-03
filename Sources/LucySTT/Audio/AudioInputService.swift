import AVFoundation
import CoreAudio
import Foundation

struct AudioInputDevice: Identifiable, Equatable {
    static let defaultID = "default"

    var id: String
    var name: String

    var isDefault: Bool { id == Self.defaultID }
}

@MainActor
final class AudioInputService: ObservableObject {
    @Published var devices: [AudioInputDevice] = [
        AudioInputDevice(id: AudioInputDevice.defaultID, name: "Default microphone")
    ]
    @Published var errorMessage: String?

    func refreshDevices() {
        do {
            let inputs = try Self.inputDevices()
            devices = [AudioInputDevice(id: AudioInputDevice.defaultID, name: "Default microphone")] + inputs
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deviceName(for id: String) -> String {
        devices.first(where: { $0.id == id })?.name ?? "Default microphone"
    }

    private static func inputDevices() throws -> [AudioInputDevice] {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        guard status == noErr else { throw AudioInputError.coreAudio(status) }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var deviceIDs = [AudioObjectID](repeating: 0, count: deviceCount)
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceIDs
        )
        guard status == noErr else { throw AudioInputError.coreAudio(status) }

        return deviceIDs.compactMap { deviceID in
            guard hasInputStreams(deviceID),
                  let uid = stringProperty(kAudioDevicePropertyDeviceUID, deviceID),
                  let name = stringProperty(kAudioObjectPropertyName, deviceID)
            else {
                return nil
            }
            return AudioInputDevice(id: uid, name: name)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func hasInputStreams(_ deviceID: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize)
        return status == noErr && dataSize > 0
    }

    private static func stringProperty(_ selector: AudioObjectPropertySelector, _ deviceID: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: CFString = "" as CFString
        var dataSize = UInt32(MemoryLayout<CFString>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &value)
        guard status == noErr else { return nil }
        return value as String
    }
}

enum AudioInputError: LocalizedError {
    case coreAudio(OSStatus)
    case permissionDenied
    case recordingFailed(String)

    var errorDescription: String? {
        switch self {
        case .coreAudio(let status):
            return "CoreAudio error \(status)."
        case .permissionDenied:
            return "Microphone access is required to record."
        case .recordingFailed(let reason):
            return reason
        }
    }
}
