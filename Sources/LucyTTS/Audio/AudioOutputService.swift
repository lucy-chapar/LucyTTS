import AVFoundation
import CoreAudio
import Foundation

struct AudioDevice: Identifiable, Equatable {
    static let defaultID = "default"

    var id: String
    var name: String

    var isDefault: Bool { id == Self.defaultID }
}

@MainActor
final class AudioOutputService: ObservableObject {
    @Published var devices: [AudioDevice] = [AudioDevice(id: AudioDevice.defaultID, name: "Default speakers/headphones")]
    @Published var errorMessage: String?

    func refreshDevices() {
        do {
            let outputDevices = try Self.outputDevices()
            devices = [AudioDevice(id: AudioDevice.defaultID, name: "Default speakers/headphones")] + outputDevices
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deviceName(for id: String) -> String {
        devices.first(where: { $0.id == id })?.name ?? "Default speakers/headphones"
    }

    private static func outputDevices() throws -> [AudioDevice] {
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
        guard status == noErr else { throw AudioDeviceError.coreAudio(status) }

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
        guard status == noErr else { throw AudioDeviceError.coreAudio(status) }

        return deviceIDs.compactMap { deviceID in
            guard hasOutputStreams(deviceID), let uid = stringProperty(kAudioDevicePropertyDeviceUID, deviceID), let name = stringProperty(kAudioObjectPropertyName, deviceID) else {
                return nil
            }
            return AudioDevice(id: uid, name: name)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func hasOutputStreams(_ deviceID: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeOutput,
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

enum AudioDeviceError: LocalizedError {
    case coreAudio(OSStatus)
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case .coreAudio(let status):
            return "CoreAudio error \(status)."
        case .unavailable(let name):
            return "Output device unavailable: \(name)"
        }
    }
}
