import AVFoundation
import Foundation

final class AudioPlaybackService: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var playbackContinuation: CheckedContinuation<Void, Error>?
    private var stoppedByUser = false

    func play(data: Data, outputDeviceID: String?) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let player = try AVAudioPlayer(data: data)
                player.delegate = self
                if let outputDeviceID, outputDeviceID != AudioDevice.defaultID {
                    player.currentDevice = outputDeviceID
                }
                guard player.prepareToPlay(), player.play() else {
                    throw PlaybackError.failedToStart
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
        playbackContinuation?.resume(throwing: PlaybackError.stopped)
        playbackContinuation = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
        guard let continuation = playbackContinuation else { return }
        playbackContinuation = nil
        if flag {
            continuation.resume()
        } else if stoppedByUser {
            continuation.resume(throwing: PlaybackError.stopped)
        } else {
            continuation.resume(throwing: PlaybackError.playbackFailed)
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.player = nil
        let playbackError = error ?? PlaybackError.playbackFailed
        playbackContinuation?.resume(throwing: playbackError)
        playbackContinuation = nil
    }
}

enum PlaybackError: LocalizedError {
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
