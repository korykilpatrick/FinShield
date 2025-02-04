import SwiftUI
import AVKit

struct VideoCellView: View {
    let video: Video
    @State private var player: AVPlayer? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
                    .ignoresSafeArea()
            } else {
                Color.black
            }
            // Overlay caption and link to comments
            VStack {
                Spacer()
                HStack {
                    Text(video.caption)
                        .foregroundColor(.white)
                        .padding()
                    Spacer()
                    NavigationLink(destination: CommentsView(videoID: video.id)) {
                        Image(systemName: "message")
                            .foregroundColor(.white)
                            .padding()
                    }
                }
            }
        }
        .onAppear {
            if player == nil {
                player = AVPlayer(url: video.videoURL)
            }
        }
    }
}
