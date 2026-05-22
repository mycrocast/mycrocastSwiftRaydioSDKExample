import Foundation
import AVFoundation
import SwiftRaydioSDK

@MainActor
class SpotModel: ObservableObject {
    
    @Published
    var isPlaying: Bool = false
    
    @Published
    var currentTime: String = "00:00"
    
    @Published
    var totalTime: String = "00:00"
    
    var onSpotPlayed: (Int) -> Void
    var audioSpotPlayer: AudioSpotPlayer? = nil
    var activeSpot: MycrocastSpot?
    
    init(onSpotPlayed: @escaping (Int) -> Void) {
        self.onSpotPlayed = onSpotPlayed
    }
    
    func formatDuration(_ seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: TimeInterval(seconds)) ?? "00:00"
    }
    
    func setSpot(_ spot: MycrocastSpot) {
  
        if let player = self.audioSpotPlayer {
            player.stop()
            self.audioSpotPlayer = nil
        }
        
        self.audioSpotPlayer = AudioSpotPlayer()
        
        self.audioSpotPlayer!.onCompletion = { [weak self] success in
            if let this = self {
                if let spot = this.activeSpot {
                    this.isPlaying = false
                    this.currentTime = this.formatDuration(spot.duration)
                    this.onSpotPlayed(spot.id)
                }
            }
        }
        
        self.audioSpotPlayer!.onTimeUpdate = { [weak self] time in
            if let this = self {
                self?.currentTime = this.formatDuration(Int(time))
            }
        }
        
        self.activeSpot = spot
        self.currentTime = "00:00"
        self.totalTime = self.formatDuration(spot.duration)
        
        if let url = URL(string: spot.url) {
            self.audioSpotPlayer!.play(url: url)
        }
    }
    
}
