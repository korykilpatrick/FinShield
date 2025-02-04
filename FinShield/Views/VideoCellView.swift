import SwiftUI
import AVKit

struct VideoCellView: View {
    let video: Video
    @State private var player: AVPlayer? = nil
    @State private var playerError: Error? = nil
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                Color.black
            }
            // Show error if one exists
            if let error = playerError {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onAppear {
            if player == nil {
                let item = AVPlayerItem(url: video.videoURL)
                // Observe for playback errors
                NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime,
                                                       object: item,
                                                       queue: .main) { notification in
                    if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                        playerError = error
                        print("AVPlayer error: \(error.localizedDescription)")
                    }
                }
                player = AVPlayer(playerItem: item)
            }
        }
    }
}
