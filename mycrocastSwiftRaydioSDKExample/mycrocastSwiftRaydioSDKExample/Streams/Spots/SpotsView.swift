import SwiftUI


struct SpotsView: View {
    
    @ObservedObject
    var spotsViewModel: SpotsModel

    init(spotsViewModel: SpotsModel) {
        self.spotsViewModel = spotsViewModel
    }
    
    
    var body: some View {
        if (spotsViewModel.activeSpot != nil) {
            SpotView(spot: spotsViewModel.activeSpot, spotModel: SpotModel() {
                spot in
                spotsViewModel.onSpotPlayed(spotId: spot)
            }).id(spotsViewModel.activeSpot!.id)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .transition(.opacity)
            .animation(.easeInOut, value: spotsViewModel.activeSpot)

        }
    }
}
