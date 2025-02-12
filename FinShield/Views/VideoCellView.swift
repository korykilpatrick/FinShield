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

    // Fact-check overlay states
    @State private var shownFactCheckIDs = Set<String>()
    @State private var factCheckPopups: [FactCheckResult] = []
    @State private var showPopupOverlay = false

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
                            print("[VideoCellView] onAppear: activePage = \(activePage), index = \(index)")
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
                // Overlays
                .overlay(
                    ZStack(alignment: .topTrailing) {
                        // Fact-check popup overlays, displayed at top-right
                        VStack(spacing: 8) {
                            ForEach(factCheckPopups, id: \.id) { fc in
                                HStack(alignment: .center, spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.yellow)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(fc.claimText)
                                            .font(.caption)
                                            .bold()
                                    }
                                }
                                .padding(8)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                                .transition(.move(edge: .top))
                            }
                            Spacer()
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 16)
                    },
                    alignment: .topTrailing
                )
                // Bottom overlay (caption and sidebar)
                .overlay(
                    ZStack(alignment: .bottom) {
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
                        .padding(.bottom, 60)
                        
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
                        .padding(.bottom, 30)
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
                            let status = asset.statusOfValue(forKey: key, error: &error)
                            if status != .loaded {
                                allLoaded = false
                                break
                            }
                        }
                        if allLoaded {
                            let item = AVPlayerItem(asset: asset)
                            let newPlayer = AVPlayer(playerItem: item)
                            self.player = newPlayer
                            self.isLoading = false
                            self.updateDuration(item)
                            self.attachTimeObserver(to: newPlayer)
                            if self.activePage == self.index {
                                newPlayer.play()
                            }
                        } else {
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
    
    private func updateDuration(_ item: AVPlayerItem?) {
        guard let item = item else { return }
        let durationSeconds = CMTimeGetSeconds(item.duration)
        if durationSeconds > 1 {
            totalDuration = durationSeconds
        }
    }
    
    private func observeComments() {
        // Placeholder for comments observation.
    }
    
    private func attachTimeObserver(to avPlayer: AVPlayer) {
        let interval = CMTimeMakeWithSeconds(0.25, preferredTimescale: 600)
        timeObserverToken = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            let secs = CMTimeGetSeconds(time)
            print("[VideoCellView] Time observer update: currentTime = \(secs)")
            self.currentTime = secs
            self.maybeShowFactCheckPopup(forTime: secs)
        }
    }
    
    private func maybeShowFactCheckPopup(forTime currentT: Double) {
        print("[VideoCellView] Checking fact-check popups at currentTime: \(currentT)")
        for fc in video.factCheckResults {
            print("[VideoCellView] Evaluating fact-check result id: \(fc.id) with endTime: \(fc.endTime) (currentTime: \(currentT))")
            if currentT >= fc.endTime, !shownFactCheckIDs.contains(fc.id) {
                print("[VideoCellView] Triggering popup for fact-check result id: \(fc.id)")
                shownFactCheckIDs.insert(fc.id)
                factCheckPopups.append(fc)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if let idx = self.factCheckPopups.firstIndex(where: { $0.id == fc.id }) {
                        print("[VideoCellView] Removing popup for fact-check result id: \(fc.id) after delay")
                        self.factCheckPopups.remove(at: idx)
                    }
                }
            }
        }
    }
    
    private func cleanupPlayer() {
        if let token = timeObserverToken, let player = player {
            player.removeTimeObserver(token)
        }
        timeObserverToken = nil
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
            }
            .padding(8)
            .background(isCaptionExpanded ? Color.black.opacity(0.3) : Color.clear)
            .cornerRadius(8)
            .shadow(
                color: isCaptionExpanded ? Color.black.opacity(0.8) : Color.clear,
                radius: isCaptionExpanded ? 4 : 0,
                x: 0, y: 2
            )
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
