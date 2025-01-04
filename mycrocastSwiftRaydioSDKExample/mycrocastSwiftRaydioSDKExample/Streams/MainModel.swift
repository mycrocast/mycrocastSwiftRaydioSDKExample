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

    var sdk: MycrocastRaydioSDK

    init() {
        self.sdk = RaydioSDK.shared.start("1567504890375_8741a554-c25e-428f-a807-a69bac373315-9999")
        
        self.sdk.streamsAccess.streams$.sink {
            streams in
            self.streams = streams
        }.store(in: &self.cancelable)
        
        self.sdk.streamsAccess.streamAdded$.sink {
            added in
            print("Stream was added " + added.title)
        }.store(in: &self.cancelable)

        self.sdk.streamsAccess.streamRemoved$.sink {
            added in
            print("Stream was removed " + added.title)
        }.store(in: &self.cancelable)
        
        self.sdk.streamsAccess.streamUpdated$.sink { [unowned self]
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
        
        self.sdk.logAccess.jsonLog$.sink {
            log in
            print(log)
        }.store(in: &self.cancelable)
        
        self.sdk.sdkStateAccess.sdkState$.sink {
            state in
            print("SDK State: " )
            print(state)
        }.store(in: &self.cancelable)
        
        self.sdk.listenStateAccess.listenState$.sink {
            state in
            print(state)
            if (state == .playing) {
                print("Audio is playing")
                // TODO you could stop the timer if you
                // have one for the connection issue
                // if we automatically play again, the stream was reconected
            }
        }.store(in: &self.cancelable)
    }


    func onAppear() {
       Task {
            let success = await self.sdk.connect()
           if (!success) {
               print("Failed to connect. Is the network connection present?")
           }
            self.networkMonitor.networkChanged$
                .sink { [weak self]
                networkAvailable in
                    if let this = self {
                        if (networkAvailable) {
                            Task {
                                let result = await this.sdk.onConnectionReestablished()
                                if (!result) {
                                    print("Failed to reconnect")
                                    return
                                }
                                guard let activeStream = this.activeStream else {
                                    return
                                }
                                let reconnectAudioError = await this.sdk.reconnectAudio()
                                if let error = reconnectAudioError {
                                    this.activeStream = nil
                                }
                            }
                            return
                        }
                        this.sdk.onConnectionLost()
                    }
                }.store(in: &self.cancelable)
        }
    }

    func onWentToBackground() {
        self.sdk.onBackgroundEntered()
    }

    func onWentToForeground() {
        Task {
            // TODO evaluate
            if (await self.sdk.onForegroundEntered()) {
                let result = await self.sdk.reconnectAudio()
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
        if let activeStream = self.activeStream {
            self.sdk.pauseCurrentStream()
            self.activeStream = nil
            if (activeStream == streamId) {
                return
            }
        }
        self.activeStream = streamId
        Task {
           let result = await self.sdk.playStream(streamId)
            print(result)
        }
    }
}
