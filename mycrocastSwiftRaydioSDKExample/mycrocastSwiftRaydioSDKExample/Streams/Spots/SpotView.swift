import SwiftUI
import SwiftRaydioSDK

struct SpotView: View {
    
    var spot: MycrocastSpot?
    
    @ObservedObject
    var spotModel: SpotModel
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                VStack {
                    Text("Advertisement playing please wait")
                    if (spot != nil && spot!.title != nil) {
                        Text(spot!.title!)
                    }
                }
                .padding()
                Spacer() 
                if (spot != nil && spot!.bannerUrl != nil) {
                    Image(spot!.bannerUrl!)
                        .frame(width: geometry.size.width * 0.8, height:geometry.size.width * 0.8)
                        .background(Color.red)
                }
                Spacer()
                Text(spotModel.currentTime + " / " + spotModel.totalTime)
                Spacer()
            }
            .onAppear(){
                if let spot = spot {
                    spotModel.setSpot(spot)
                }
            }
            .onChange(of: spot) { newValue in
                if let spot = newValue {
                    spotModel.setSpot(spot)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}


#Preview {
    SpotView(spot: nil, spotModel: SpotModel(onSpotPlayed: {_  in
        
    }))
}
