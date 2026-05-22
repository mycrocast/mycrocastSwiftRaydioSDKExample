import SwiftRaydioSDK
import Combine

@MainActor
class SpotsModel : ObservableObject {
        
    @Published
    public var activeSpot: MycrocastSpot?
    
    private var spotAccess: SpotAccess
    private var cancelAble: Set<AnyCancellable> = []
    
    private var spots: [MycrocastSpot] = []
    
    init(spotAccess: SpotAccess) {
        self.spotAccess = spotAccess
        
        self.spotAccess.spotPlay$.sink {
            spots in
            self.spots.append(contentsOf: spots)
            if (self.activeSpot == nil) {
                self.activeSpot = self.spots[0]
            }
            
        }.store(in: &self.cancelAble)
    }
    
    func onSpotPlayed(spotId: Int) {
        self.spots.removeAll {
            spot in
            spot.id == spotId
        }
        self.spotAccess.spotPlayed(spotId: spotId)
        if (self.spots.isEmpty) {
            self.activeSpot = nil
            return
        }
        self.activeSpot = self.spots[0]
    }
}
