import Foundation
import SwiftUI
import SwiftRaydioSDK
import Combine
import AVFoundation;
import MediaPlayer

class MainModel: ObservableObject {

    /// used to observe network changes
    @Injected(\.networkMonitor)
    private var networkMonitor: NetworkMonitorProviding

    private var cancelable: Set<AnyCancellable> = []

    @Published
    var streams: [MycrocastStream] = []

    @Published
    var activeStream: String? = nil

    @Published
    var initialised: Bool = false

    var sdk: MycrocastRaydioSDK?

    var locationManager: LocationManager = LocationManager()

    init(useLocation: Bool = false) {
        if (!useLocation) {
            self.initSDK()
            return
        }

        locationManager.location$.sink ( receiveCompletion: {
            completion in
            switch completion {
            case .finished:
                print("Finished - should not be called")
            case .failure(let error):
                print("failed with \(error)")
            }
        }, receiveValue: {
            value in
            if (self.sdk != nil) {
                return
            }
            guard let location = value else {
                return
            }
            self.initSDK(location: Location(latitude: location.latitude, longitude: location.longitude))

        }).store(in: &self.cancelable)

        locationManager.requestLocation()
    }

    private func initSDK(location: Location? = nil) {
        let sdk = RaydioSDK.shared.start("1567504890375_8741a554-c25e-428f-a807-a69bac373315-9999", location: location)


        sdk.streamsAccess.streams$.sink {
            streams in
            self.streams = streams
        }.store(in: &self.cancelable)

        sdk.streamsAccess.streamAdded$.sink {
            added in
            print("Stream was added " + added.title)
        }.store(in: &self.cancelable)

        sdk.streamsAccess.streamRemoved$.sink {
            added in
            print("Stream was removed " + added.title)
        }.store(in: &self.cancelable)

        sdk.streamsAccess.streamUpdated$.sink { [unowned self]
            added in
            print("Stream was updated " + added.title)
            if let activeStream = sdk.activeStream {
                if (added.streamId == activeStream && added.connectionIssues) {
                    // Could display a toast
                    // Start a timer that calls to refresh the streams after a minute to remove
                    // the stream if the streamer did not reconnect in time...
                    print("Streamer has connection issue!")
                }
            }

        }.store(in: &self.cancelable)

        sdk.logAccess.jsonLog$.sink {
            log in
            print(log)
        }.store(in: &self.cancelable)

        sdk.sdkStateAccess.sdkState$.sink {
            state in
            print("SDK State: " )
            print(state)
        }.store(in: &self.cancelable)

        sdk.listenStateAccess.listenState$.sink {
            state in
            print(state)
            if (state == .playing) {
                print("Audio is playing")
                // TODO you could stop the timer if you
                // have one for the connection issue
                // if we automatically play again, the stream was reconected
            }
        }.store(in: &self.cancelable)

        self.sdk = sdk
        self.initialised = true
        self.onAppear()
    }


    func onAppear() {
        Task {
            guard let sdk = self.sdk else {
                return
            }
            let success = await sdk.connect()
            if (!success) {
                print("Failed to connect. Is the network connection present?")
            }
            self.networkMonitor.networkChanged$
                .sink { [weak self]
                    networkAvailable in
                    if let this = self {
                        if (networkAvailable) {
                            Task {
                                guard let sdk = this.sdk else {
                                    return
                                }
                                let result = await sdk.onConnectionReestablished()
                                if (!result) {
                                    print("Failed to reconnect")
                                    return
                                }
                                guard let activeStream = this.activeStream else {
                                    return
                                }
                                let reconnectAudioError = await sdk.reconnectAudio()
                                if let error = reconnectAudioError {
                                    this.activeStream = nil
                                }
                            }
                            return
                        }
                        sdk.onConnectionLost()
                    }
                }.store(in: &self.cancelable)
        }
    }

    func onWentToBackground() {
        guard let sdk = self.sdk else {
            return
        }
        sdk.onBackgroundEntered()
    }

    func onWentToForeground() {
        Task {
            guard let sdk = self.sdk else {
                return
            }
            if (await sdk.onForegroundEntered()) {
                let result = await sdk.reconnectAudio()
            }
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
        }
    }

    func onStreamPressed(_ streamId: String) {
        self.configureAudioSession()
        guard let sdk = self.sdk else {
            return
        }
        if let activeStream = self.activeStream {
            sdk.pauseCurrentStream()
            self.activeStream = nil
            if (activeStream == streamId) {
                return
            }
        }
        self.activeStream = streamId
        Task {
            let result = await sdk.playStream(streamId)
            print(result)
        }
    }
}
