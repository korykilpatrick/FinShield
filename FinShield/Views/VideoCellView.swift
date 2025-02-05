import SwiftUI
import AVKit
import FirebaseFirestore

/// A SwiftUI view representing a single video cell in the video feed.
/// This view handles video playback, displays video metadata (username, title, caption, and timestamp),
/// and provides interactive controls for sharing, liking, and commenting.
struct VideoCellView: View {
    /// The video model containing metadata and playback URL.
    let video: Video
    /// Optionally, a preloaded AVPlayer for faster playback.
    let preloadedPlayer: AVPlayer?
    
    // MARK: - State Properties
    
    /// The active AVPlayer instance.
    @State private var player: AVPlayer?
    /// Any error encountered during player setup.
    @State private var playerError: Error?
    /// Indicates whether the video is currently loading.
    @State private var isLoading = true
    /// Tracks the liked state for UI purposes.
    @State private var isLiked = false
    /// Number of likes (for display only).
    @State private var likesCount = 0
    /// Number of comments (updated in real time).
    @State private var commentsCount = 0
    /// Number of shares (for display only).
    @State private var sharesCount = 0
    /// Controls the presentation of the comments sheet.
    @State private var showComments = false
    /// Listener registration for comments updates.
    @State private var commentsListener: ListenerRegistration?
    
    /// Determines if the caption is expanded (shows at least a partial expansion).
    @State private var isCaptionExpanded = false
    /// Determines if the caption is fully expanded (shows all text).
    @State private var isCaptionFullyExpanded = false
    
    /// Computes the caption text based on the expansion state.
    /// - When collapsed: shows the first 50 characters with an ellipsis if needed.
    /// - When expanded partially: shows the first 200 characters with an ellipsis if the caption is long.
    /// - When fully expanded: shows the full caption.
    private var displayedCaption: String {
        if !isCaptionExpanded {
            return video.caption.count > 50 ? String(video.caption.prefix(50)) + "..." : video.caption
        } else if !isCaptionFullyExpanded {
            return video.caption.count > 200 ? String(video.caption.prefix(200)) + "..." : video.caption
        } else {
            return video.caption
        }
    }
    
    /// Firestore database reference.
    private let db = Firestore.firestore()

    // MARK: - View Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // MARK: Video Playback or Placeholder
                
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
                
                // MARK: Error Overlay
                
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
                
                // MARK: Metadata and Action Overlay
                
                VStack {
                    Spacer()
                    HStack(alignment: .bottom) {
                        // Left side: Video metadata
                        VStack(alignment: .leading, spacing: 8) {
                            // Display the username without an '@' symbol.
                            Text(video.username)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Display the video title.
                            Text(video.videoTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            
                            // Display the video caption with truncation and expansion behavior.
                            VStack(alignment: .leading, spacing: 4) {
                                // Tapping on the caption toggles a partial expansion.
                                Text(displayedCaption)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .onTapGesture {
                                        if !isCaptionExpanded {
                                            withAnimation { isCaptionExpanded = true }
                                        }
                                    }
                                
                                // If the caption is expandable, show buttons to control its state.
                                if video.caption.count > 50 && isCaptionExpanded {
                                    if video.caption.count > 200 {
                                        if isCaptionFullyExpanded {
                                            // Fully expanded: show only "Show Less".
                                            Button("Show Less") {
                                                withAnimation {
                                                    isCaptionExpanded = false
                                                    isCaptionFullyExpanded = false
                                                }
                                            }
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        } else {
                                            // Partially expanded: show both "Show More" and "Show Less" side by side.
                                            HStack {
                                                Button("Show More") {
                                                    withAnimation { isCaptionFullyExpanded = true }
                                                }
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                                
                                                Button("Show Less") {
                                                    withAnimation {
                                                        isCaptionExpanded = false
                                                        isCaptionFullyExpanded = false
                                                    }
                                                }
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                            }
                                        }
                                    } else {
                                        // Caption is expanded and its length is <= 200: show only "Show Less".
                                        Button("Show Less") {
                                            withAnimation {
                                                isCaptionExpanded = false
                                                isCaptionFullyExpanded = false
                                            }
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            // Display a relative timestamp (e.g., "5 minutes ago").
                            Text(video.timestamp, style: .relative)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        .padding(.leading)
                        .padding(.bottom, 20)
                        
                        Spacer()
                        
                        // Right side: Interactive action buttons.
                        VStack(spacing: 20) {
                            // Share button.
                            VStack(spacing: 4) {
                                Button(action: {
                                    // Implement share action here.
                                }) {
                                    Image(systemName: "arrowshape.turn.up.right")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                }
                                Text("\(sharesCount)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            // Like button.
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
                            // Comment button.
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
                            // Profile button (or additional options).
                            Button(action: {
                                // Implement profile or additional actions here.
                            }) {
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
        // Present the comments view as a modal sheet.
        .sheet(isPresented: $showComments) {
            CommentsView(videoID: video.id)
        }
    }
    
    // MARK: - Player Setup and Cleanup
    
    /// Sets up the AVPlayer for video playback.
    /// - If a preloaded player is available, it uses that directly.
    /// - Otherwise, it loads the video asset asynchronously.
    private func setupPlayer() {
        let startTime = Date()
        print("[\(startTime)] setupPlayer => video \(video.id)")
        
        // Listen for comment changes in Firestore.
        commentsListener = db.collection("videos").document(video.id)
            .collection("comments")
            .addSnapshotListener { snapshot, _ in
                commentsCount = snapshot?.documents.count ?? 0
            }
        
        // Use the preloaded player if provided.
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
    
    /// Cleans up the player by stopping playback, removing observers, and detaching Firestore listeners.
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

/// A wrapper for AVPlayerViewController to integrate AVPlayer within SwiftUI.
struct CustomVideoPlayer: UIViewControllerRepresentable {
    /// The AVPlayer instance used for video playback.
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