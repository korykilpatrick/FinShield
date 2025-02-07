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

    @State private var isLiked = false
    @State private var likesCount: Int
    @State private var isBookmarked = false
    @State private var bookmarksCount: Int
    @State private var commentsCount = 0
    @State private var sharesCount: Int
    @State private var showComments = false

    @State private var isCaptionExpanded = false
    @State private var isCaptionFullyExpanded = false

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
                // VIDEO LAYER: Plays the video full-screen.
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
                // INTERACTIVE OVERLAY: Captures nav, sidebar, and caption taps.
                .overlay(
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
                        onComment: {
                            showComments = true
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 20),
                    alignment: .bottom
                )
            }
        }
        .onAppear {
            setupPlayer()
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
        if player.rate == 0 {
            player.play()
        } else {
            player.pause()
        }
    }

    private func setupPlayer() {
        // Listen for comment updates.
        _ = db.collection("videos").document(video.id)
            .collection("comments")
            .addSnapshotListener { snapshot, _ in
                commentsCount = snapshot?.documents.count ?? 0
            }

        if let preloaded = preloadedPlayer {
            player = preloaded
            isLoading = false
        } else {
            isLoading = true
            DispatchQueue.global(qos: .background).async {
                let asset = AVURLAsset(url: video.videoURL,
                                       options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
                let keys = ["playable", "preferredTransform"]
                asset.loadValuesAsynchronously(forKeys: keys) {
                    DispatchQueue.main.async {
                        var allLoaded = true
                        for key in keys {
                            var error: NSError?
                            let status = asset.statusOfValue(forKey: key, error: &error)
                            if status != .loaded { allLoaded = false }
                        }
                        if allLoaded {
                            let item = AVPlayerItem(asset: asset)
                            item.preferredForwardBufferDuration = 5.0
                            let newPlayer = AVPlayer(playerItem: item)
                            newPlayer.actionAtItemEnd = .none
                            newPlayer.automaticallyWaitsToMinimizeStalling = true

                            // Loop video when it ends.
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: item,
                                queue: .main
                            ) { _ in
                                newPlayer.seek(to: .zero)
                                newPlayer.play()
                            }
                            self.player = newPlayer
                        }
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
                Text(DateUtils.formattedDate(from: video.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
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
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
