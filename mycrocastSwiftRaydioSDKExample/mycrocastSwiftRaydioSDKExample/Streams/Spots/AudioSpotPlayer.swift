import Foundation
import AVFoundation

class AudioSpotPlayer: NSObject, ObservableObject {
    private var player: AVPlayer?
    private var timeObserver: Any?

    // Callbacks
    var onTimeUpdate: ((Double) -> Void)?  // Called with the current playback time
    var onCompletion: ((Bool) -> Void)?    // Called with success or error state

    // MARK: - Initializer
    override init() {
        super.init()
    }

    // MARK: - Play Audio from URL
    func play(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        self.player = AVPlayer(playerItem: playerItem)

        // Observe playback completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        // Observe errors
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFail(_:)),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem
        )

        // Track playback time updates
        addTimeObserver()

        // Start playback
        player?.play()
    }

    // MARK: - Pause Playback
    func pause() {
        player?.pause()
    }

    // MARK: - Stop and Reset
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        removeTimeObserver()
    }

    // MARK: - Observer for Time Updates
    private func addTimeObserver() {
        guard let player = player else { return }

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), // Every second
            queue: .main
        ) { [weak self] time in
            let currentTime = CMTimeGetSeconds(time)
            self?.onTimeUpdate?(currentTime)
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    // MARK: - Playback Completion
    @objc private func playerDidFinishPlaying(_ notification: Notification) {
        onCompletion?(true)
    }

    // MARK: - Playback Failure
    @objc private func playerDidFail(_ notification: Notification) {
        onCompletion?(false)
    }

    deinit {
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self)
    }
}
