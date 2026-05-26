import AVFoundation
import Foundation

final class iOSAudioPlaybackService: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var playbackContinuation: CheckedContinuation<Void, Error>?
    private var stoppedByUser = false

    func play(data: Data) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .spokenAudio, options: [.allowBluetooth, .duckOthers])
                try session.setActive(true)

                let player = try AVAudioPlayer(data: data)
                player.delegate = self
                guard player.prepareToPlay(), player.play() else {
                    throw iOSPlaybackError.failedToStart
                }
                self.player = player
                self.playbackContinuation = continuation
                self.stoppedByUser = false
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func stopCurrent() {
        stoppedByUser = true
        player?.stop()
        player = nil
        playbackContinuation?.resume(throwing: iOSPlaybackError.stopped)
        playbackContinuation = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
        guard let continuation = playbackContinuation else { return }
        playbackContinuation = nil
        if flag {
            continuation.resume()
        } else if stoppedByUser {
            continuation.resume(throwing: iOSPlaybackError.stopped)
        } else {
            continuation.resume(throwing: iOSPlaybackError.playbackFailed)
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.player = nil
        playbackContinuation?.resume(throwing: error ?? iOSPlaybackError.playbackFailed)
        playbackContinuation = nil
    }
}

enum iOSPlaybackError: LocalizedError {
    case failedToStart
    case playbackFailed
    case stopped

    var errorDescription: String? {
        switch self {
        case .failedToStart:
            return "Audio playback could not start."
        case .playbackFailed:
            return "Audio playback failed."
        case .stopped:
            return "Playback stopped."
        }
    }
}
