import SwiftUI
import AVKit
import AVFoundation

struct VideoCellView: View {
    let video: Video
    let preloadedPlayer: AVPlayer?
    
    @State private var player: AVPlayer?
    @State private var playerError: Error?
    @State private var isLoading = true
    @State private var isLiked = false
    @State private var likesCount = 0
    @State private var commentsCount = 0
    @State private var sharesCount = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Group {
                    if let player = player {
                        CustomVideoPlayer(player: player)
                            .onAppear {
                                player.play()
                                player.automaticallyWaitsToMinimizeStalling = true
                            }
                            .onDisappear { player.pause() }
                    } else if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                    } else {
                        Color.black
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea()

                if let error = playerError {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                            .font(.largeTitle)
                        Text("Error loading video")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                    .zIndex(2)
                }
                
                // Your overlay UI remains unchanged...
                VStack {
                    Spacer()
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("@username")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text(video.caption)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            HStack {
                                Image(systemName: "music.note")
                                    .font(.system(size: 14))
                                Text("Original Sound")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.white)
                        }
                        .padding(.leading)
                        .padding(.bottom, 20)
                        
                        Spacer()
                        
                        VStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Button(action: {}) {
                                    Image(systemName: "arrowshape.turn.up.right")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                }
                                Text("\(sharesCount)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            VStack(spacing: 4) {
                                Button(action: { isLiked.toggle() }) {
                                    Image(systemName: isLiked ? "heart.fill" : "heart")
                                        .font(.system(size: 30))
                                        .foregroundColor(isLiked ? .red : .white)
                                }
                                Text("\(likesCount)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            VStack(spacing: 4) {
                                Button(action: {}) {
                                    Image(systemName: "bubble.right")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                }
                                Text("\(commentsCount)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            Button(action: {}) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing)
                        .padding(.bottom, 20)
                    }
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.3)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .zIndex(1)
            }
        }
        .onAppear { setupPlayer() }
        .onDisappear { cleanupPlayer() }
    }
    
    private func setupPlayer() {
        // Use the cached, preloaded player if available.
        if let preloadedPlayer = preloadedPlayer {
            isLoading = false
            playerError = nil
            player = preloadedPlayer
        } else {
            // Fallback: Load the asset asynchronously, ensuring both "playable" and "preferredTransform" are ready.
            isLoading = true
            let asset = AVURLAsset(url: video.videoURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
            let keys = ["playable", "preferredTransform"]
            asset.loadValuesAsynchronously(forKeys: keys) {
                DispatchQueue.main.async {
                    var allLoaded = true
                    for key in keys {
                        var error: NSError?
                        let status = asset.statusOfValue(forKey: key, error: &error)
                        if status != .loaded {
                            allLoaded = false
                            print("Failed to load key \(key): \(error?.localizedDescription ?? "unknown error")")
                            break
                        }
                    }
                    if allLoaded {
                        let playerItem = AVPlayerItem(asset: asset)
                        playerItem.preferredForwardBufferDuration = 5.0
                        let newPlayer = AVPlayer(playerItem: playerItem)
                        newPlayer.actionAtItemEnd = .none
                        
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemFailedToPlayToEndTime,
                            object: playerItem,
                            queue: .main
                        ) { notification in
                            if let err = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                                self.playerError = err
                            }
                        }
                        
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: playerItem,
                            queue: .main
                        ) { _ in
                            newPlayer.seek(to: .zero)
                            newPlayer.play()
                        }
                        
                        self.player = newPlayer
                        self.isLoading = false
                    } else {
                        self.playerError = NSError(domain: "", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "Failed to load necessary asset keys."
                        ])
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        NotificationCenter.default.removeObserver(self)
        player = nil
        isLoading = false
    }
}


// Custom VideoPlayer to prevent overlay issues
struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}
