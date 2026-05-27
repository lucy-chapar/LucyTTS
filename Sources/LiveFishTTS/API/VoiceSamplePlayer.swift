import AVFoundation
import Combine
import Foundation

@MainActor
final class VoiceSamplePlayer: ObservableObject {
    @Published private(set) var nowPlaying: URL?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastError: String?

    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var failObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?

    func toggle(url: URL) {
        if nowPlaying == url {
            stop()
        } else {
            play(url: url)
        }
    }

    func play(url: URL) {
        stop()
        lastError = nil
        nowPlaying = url
        isLoading = true

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = true
        self.player = player

        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    self.isLoading = false
                case .failed:
                    self.lastError = item.error?.localizedDescription ?? "Sample failed to load."
                    self.stop()
                default:
                    break
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.stop()
            }
        }

        failObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] note in
            Task { @MainActor [weak self] in
                let error = note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
                self?.lastError = error?.localizedDescription ?? "Sample failed to play."
                self?.stop()
            }
        }

        player.play()
    }

    func stop() {
        player?.pause()
        statusObserver?.invalidate()
        statusObserver = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        if let failObserver {
            NotificationCenter.default.removeObserver(failObserver)
            self.failObserver = nil
        }
        player = nil
        nowPlaying = nil
        isLoading = false
    }
}
