import SwiftUI
import AVKit
import FirebaseFirestore

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
    @State private var showComments = false
    
    // Track only one listener per cell
    @State private var commentsListener: ListenerRegistration?
    
    private let db = Firestore.firestore()

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Group {
                    if let player = player {
                        CustomVideoPlayer(player: player)
                            .onAppear {
                                print("[\(Date())] Playing video \(video.id)")
                                player.play()
                            }
                            .onDisappear {
                                print("[\(Date())] Pausing video \(video.id)")
                                player.pause()
                            }
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
                
                // Basic overlay
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
                                Button(action: { showComments = true }) {
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
        .sheet(isPresented: $showComments) {
            CommentsView(videoID: video.id)
        }
    }
    
    private func setupPlayer() {
        let startTime = Date()
        print("[\(startTime)] setupPlayer => video \(video.id)")
        
        // Attach single comment listener
        commentsListener = db.collection("videos").document(video.id)
            .collection("comments")
            .addSnapshotListener { snapshot, _ in
                commentsCount = snapshot?.documents.count ?? 0
            }

        // If we have a preloaded player, skip loading
        if let preloaded = preloadedPlayer {
            playerError = nil
            isLoading = false
            player = preloaded
            let elapsed = Date().timeIntervalSince(startTime)
            print("[\(Date())] Used preloaded player => setup in \(elapsed)s for \(video.id)")
        } else {
            isLoading = true
            DispatchQueue.global(qos: .background).async {
                let asset = AVURLAsset(url: self.video.videoURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
                let keys = ["playable", "preferredTransform"]
                
                asset.loadValuesAsynchronously(forKeys: keys) {
                    DispatchQueue.main.async {
                        var allLoaded = true
                        for key in keys {
                            var error: NSError?
                            let status = asset.statusOfValue(forKey: key, error: &error)
                            if status != .loaded {
                                allLoaded = false
                                self.playerError = error
                                break
                            }
                        }
                        if allLoaded {
                            let item = AVPlayerItem(asset: asset)
                            item.preferredForwardBufferDuration = 5.0
                            // Removed forced peak bitrate to allow ABR:
                            // item.preferredPeakBitRate = 500_000
                            let newPlayer = AVPlayer(playerItem: item)
                            newPlayer.actionAtItemEnd = .none
                            newPlayer.automaticallyWaitsToMinimizeStalling = true
                            
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemFailedToPlayToEndTime,
                                object: item,
                                queue: .main
                            ) { notification in
                                if let err = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                                    self.playerError = err
                                }
                            }
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: item,
                                queue: .main
                            ) { _ in
                                newPlayer.seek(to: .zero)
                                newPlayer.play()
                            }
                            
                            self.player = newPlayer
                            self.isLoading = false
                        } else {
                            self.isLoading = false
                        }
                        let elapsed = Date().timeIntervalSince(startTime)
                        print("[\(Date())] Fallback load => \(allLoaded ? "success" : "fail") in \(elapsed)s for \(self.video.id)")
                    }
                }
            }
        }
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        NotificationCenter.default.removeObserver(self)
        commentsListener?.remove()
        player = nil
        isLoading = false
        print("[\(Date())] cleanupPlayer => video \(video.id)")
    }
}

// Keep a simple custom video player
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