import SwiftUI
import AVKit
import FirebaseFirestore

struct VideoCellView: View {
    let video: Video
    let preloadedPlayer: AVPlayer?
    let index: Int
    @Binding var activePage: Int

    @State private var player: AVPlayer?
    @State private var isLoading = true

    // Interaction states
    @State private var isLiked = false
    @State private var likesCount: Int
    @State private var isBookmarked = false
    @State private var bookmarksCount: Int
    @State private var commentsCount = 0
    @State private var sharesCount: Int
    @State private var showComments = false

    // Caption expansions
    @State private var isCaptionExpanded = false
    @State private var isCaptionFullyExpanded = false

    // Track time/duration for scrubber
    @State private var currentTime: Double = 0
    @State private var totalDuration: Double = 1
    @State private var timeObserverToken: Any?

    @EnvironmentObject var scrubbingManager: ScrubbingManager

    private let db = Firestore.firestore()

    private var displayedCaption: String {
        if !isCaptionExpanded {
            return video.caption.count > 50 ? String(video.caption.prefix(50)) + "..." : video.caption
        } else if !isCaptionFullyExpanded {
            return video.caption.count > 200 ? String(video.caption.prefix(200)) + "..." : video.caption
        } else {
            return video.caption
        }
    }

    init(video: Video, preloadedPlayer: AVPlayer?, index: Int, activePage: Binding<Int>) {
        self.video = video
        self.preloadedPlayer = preloadedPlayer
        self.index = index
        self._activePage = activePage
        _likesCount = State(initialValue: video.numLikes)
        _bookmarksCount = State(initialValue: video.numBookmarks)
        _sharesCount = State(initialValue: video.numShares)
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                // Video layer
                Group {
                    if let player = player {
                        CustomVideoPlayer(player: player, onTap: {
                            togglePlayback()
                        })
                        .ignoresSafeArea()
                        .onAppear {
                            if activePage == index {
                                player.play()
                            }
                        }
                        .onDisappear {
                            player.pause()
                        }
                    } else if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .background(Color.black)
                            .ignoresSafeArea()
                    } else {
                        Color.black.ignoresSafeArea()
                    }
                }
                // Bottom overlay (caption and sidebar)
                .overlay(
                    ZStack(alignment: .bottom) {
                        // The video data (caption and sidebar) remains fixed.
                        BottomOverlayView(
                            video: video,
                            displayedCaption: displayedCaption,
                            isCaptionExpanded: $isCaptionExpanded,
                            isCaptionFullyExpanded: $isCaptionFullyExpanded,
                            likesCount: $likesCount,
                            bookmarksCount: $bookmarksCount,
                            commentsCount: commentsCount,
                            isLiked: isLiked,
                            isBookmarked: isBookmarked,
                            onLike: {
                                isLiked.toggle()
                                likesCount += isLiked ? 1 : -1
                            },
                            onBookmark: {
                                isBookmarked.toggle()
                                bookmarksCount += isBookmarked ? 1 : -1
                            },
                            onComment: { showComments = true }
                        )
                        .opacity(scrubbingManager.isScrubbing ? 0 : 1)
                        // Position the BottomOverlayView with some bottom padding
                        .padding(.bottom, 60)
                        
                        // The scrubber is overlaid on top but does not push the other view.
                        VideoScrubberView(
                            currentTime: $currentTime,
                            totalDuration: $totalDuration,
                            onScrub: { newTime in
                                guard let player = player else { return }
                                let target = CMTime(seconds: newTime, preferredTimescale: 600)
                                player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .ignoresSafeArea(),
                    alignment: .bottom
                )
            }
        }
        .onAppear {
            setupPlayer()
            observeComments()
        }
        .onDisappear {
            cleanupPlayer()
        }
        .onChange(of: activePage) { newValue in
            if newValue != index {
                player?.pause()
            } else {
                player?.play()
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(videoID: video.id)
        }
    }

    private func togglePlayback() {
        guard let player = player else { return }
        player.rate == 0 ? player.play() : player.pause()
    }

    private func setupPlayer() {
        guard player == nil else { return }
        if let preloaded = preloadedPlayer {
            player = preloaded
            isLoading = false
            attachTimeObserver(to: preloaded)
            updateDuration(preloaded.currentItem)
        } else {
            isLoading = true
            DispatchQueue.global(qos: .background).async {
                let asset = AVURLAsset(url: self.video.videoURL,
                                       options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
                let keys = ["playable", "preferredTransform", "duration"]
                asset.loadValuesAsynchronously(forKeys: keys) {
                    DispatchQueue.main.async {
                        var allLoaded = true
                        for key in keys {
                            var error: NSError?
                            if asset.statusOfValue(forKey: key, error: &error) != .loaded {
                                allLoaded = false
                            }
                        }
                        if allLoaded {
                            let item = AVPlayerItem(asset: asset)
                            item.preferredForwardBufferDuration = 5.0
                            let newPlayer = AVPlayer(playerItem: item)
                            newPlayer.actionAtItemEnd = .none
                            newPlayer.automaticallyWaitsToMinimizeStalling = true
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: item,
                                queue: .main
                            ) { _ in
                                newPlayer.seek(to: .zero)
                                newPlayer.play()
                            }
                            self.player = newPlayer
                            self.attachTimeObserver(to: newPlayer)
                            self.updateDuration(item)
                        }
                        self.isLoading = false
                    }
                }
            }
        }
    }

    private func observeComments() {
        _ = db.collection("videos").document(video.id)
            .collection("comments")
            .addSnapshotListener { snapshot, _ in
                commentsCount = snapshot?.documents.count ?? 0
            }
    }

    private func cleanupPlayer() {
        if let player = player {
            player.pause()
            if let token = timeObserverToken {
                player.removeTimeObserver(token)
            }
        }
        NotificationCenter.default.removeObserver(self)
        player = nil
        isLoading = false
        timeObserverToken = nil
    }

    private func attachTimeObserver(to avPlayer: AVPlayer) {
        let interval = CMTimeMakeWithSeconds(0.5, preferredTimescale: 600)
        timeObserverToken = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            self.currentTime = time.seconds
        }
    }

    private func updateDuration(_ item: AVPlayerItem?) {
        guard let item = item else { return }
        let durationSeconds = item.asset.duration.seconds
        if durationSeconds.isFinite && durationSeconds > 0 {
            totalDuration = durationSeconds
        }
    }
}

private struct BottomOverlayView: View {
    let video: Video
    let displayedCaption: String
    @Binding var isCaptionExpanded: Bool
    @Binding var isCaptionFullyExpanded: Bool
    @Binding var likesCount: Int
    @Binding var bookmarksCount: Int
    let commentsCount: Int
    let isLiked: Bool
    let isBookmarked: Bool
    let onLike: () -> Void
    let onBookmark: () -> Void
    let onComment: () -> Void

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text(video.username)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(video.videoTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                if !video.caption.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayedCaption)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .onTapGesture {
                                if !isCaptionExpanded {
                                    withAnimation { isCaptionExpanded = true }
                                }
                            }
                        if video.caption.count > 50 && isCaptionExpanded {
                            if video.caption.count > 200 {
                                if isCaptionFullyExpanded {
                                    Button("Show Less") {
                                        withAnimation {
                                            isCaptionExpanded = false
                                            isCaptionFullyExpanded = false
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                } else {
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
                }
                // Date text removed.
            }
            Spacer()
            VideoSidebarView(
                numLikes: likesCount,
                numComments: commentsCount,
                numBookmarks: bookmarksCount,
                numShares: video.numShares,
                isLiked: isLiked,
                isBookmarked: isBookmarked,
                onLike: onLike,
                onBookmark: onBookmark,
                onComment: onComment
            )
        }
        .padding(.leading, 10)
        .padding(.vertical, 5)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .fixedSize(horizontal: false, vertical: true)
    }
}
