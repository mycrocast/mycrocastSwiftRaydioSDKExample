import SwiftUI
import SwiftRaydioSDK

struct ContentView: View {

    @StateObject
    var model = MainModel(useLocation: false)

    var body: some View {
        ZStack {
            StreamListView(model: model)
            if (model.initialised) {
                SpotsView(spotsViewModel: SpotsModel(spotAccess: model.sdk!.spotAccess))
            }
        }.onAppear() {
            self.model.onAppear()
        }.onAppWentToBackground {
            self.model.onWentToBackground()
        }.onAppCameToForeground {
            self.model.onWentToForeground()
        }
    }
}

#Preview {
    ContentView()
}

struct StreamListView: View {

    @ObservedObject
    var model: MainModel

    var body: some View {
        ZStack {
            List {
                ForEach(model.streams, id: \.streamId) { stream in
                    StreamCell(
                        liveStream: stream,
                        isPlaying: model.activeStream == stream.streamId
                    ) { tappedStream in
                        model.onStreamPressed(tappedStream)
                    }
                }
            }
            if (model.streams.count == 0) {
                Text("No streams available")
                    .font(.title)
            }
        }
    }
}
