import AVFoundation
import CoreAudio
import Foundation

@MainActor
final class SessionRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsedSeconds: TimeInterval = 0

    private var engine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    private var timer: Timer?
    private var recordingStartedAt: Date?

    func start(inputDeviceID: String) async throws -> URL {
        guard !isRecording else {
            throw AudioInputError.recordingFailed("Already recording.")
        }

        let granted = await requestMicrophonePermission()
        guard granted else { throw AudioInputError.permissionDenied }

        if inputDeviceID != AudioInputDevice.defaultID {
            try setDefaultInputDevice(uid: inputDeviceID)
        }

        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("lucy-stt-\(UUID().uuidString).caf")
        let file = try AVAudioFile(forWriting: url, settings: format.settings)

        input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            do {
                try file.write(from: buffer)
            } catch {
                // Tap callbacks cannot throw; drop frames on write failure.
            }
        }

        engine.prepare()
        try engine.start()

        self.engine = engine
        self.audioFile = file
        self.recordingURL = url
        self.isRecording = true
        self.recordingStartedAt = Date()
        self.elapsedSeconds = 0
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.recordingStartedAt else { return }
                self.elapsedSeconds = Date().timeIntervalSince(start)
            }
        }

        return url
    }

    func stop() -> URL? {
        guard isRecording else { return recordingURL }

        timer?.invalidate()
        timer = nil
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        audioFile = nil
        isRecording = false

        return recordingURL
    }

    private func requestMicrophonePermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        default:
            return false
        }
    }

    private func setDefaultInputDevice(uid: String) throws {
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

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var deviceIDs = [AudioObjectID](repeating: 0, count: count)
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceIDs
        )
        guard status == noErr else { throw AudioInputError.coreAudio(status) }

        for deviceID in deviceIDs {
            guard let deviceUID = uidString(for: deviceID), deviceUID == uid else { continue }

            var defaultInput = deviceID
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultInputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            let setStatus = AudioObjectSetPropertyData(
                AudioObjectID(kAudioObjectSystemObject),
                &address,
                0,
                nil,
                UInt32(MemoryLayout<AudioObjectID>.size),
                &defaultInput
            )
            guard setStatus == noErr else { throw AudioInputError.coreAudio(setStatus) }
            return
        }

        throw AudioInputError.recordingFailed("Input device not found.")
    }

    private func uidString(for deviceID: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
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
