import SwiftUI
import AVKit
import FirebaseFirestore
import Foundation

struct VideoCellView: View {
    let video: Video
    let preloadedPlayer: AVPlayer?
    let index: Int
    @Binding var activePage: Int

    @State private var player: AVPlayer?
    @State private var playerError: Error?
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

    // Compute a shortened caption as needed.
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
        GeometryReader { geometry in
            ZStack {
                // VIDEO LAYER: Full-screen video player.
                Group {
                    if let player = player {
                        CustomVideoPlayer(player: player, onTap: {
                            togglePlayback()
                        })
                        .ignoresSafeArea()
                        .onAppear {
                            print("[VideoCellView] onAppear => Start video \(video.id), index=\(index).")
                            if activePage == index {
                                player.play()
                                print("[VideoCellView] Auto-play => video \(video.id).")
                            }
                        }
                        .onDisappear {
                            print("[VideoCellView] onDisappear => Pause video \(video.id).")
                            player.pause()
                        }
                    } else if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .background(Color.black)
                            .ignoresSafeArea()
                            .onAppear {
                                print("[VideoCellView] isLoading => video \(video.id).")
                            }
                    } else {
                        Color.black.ignoresSafeArea()
                    }
                }
            }
            // INTERACTIVE OVERLAY: Only covers the bottom area.
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
                        print("[VideoCellView] onLike => isLiked=\(isLiked), total=\(likesCount). VideoID=\(video.id)")
                    },
                    onBookmark: {
                        isBookmarked.toggle()
                        bookmarksCount += isBookmarked ? 1 : -1
                        print("[VideoCellView] onBookmark => isBookmarked=\(isBookmarked), total=\(bookmarksCount). VideoID=\(video.id)")
                    },
                    onComment: {
                        showComments = true
                        print("[VideoCellView] onComment => show sheet => VideoID=\(video.id)")
                    }
                )
                .padding(.horizontal)
                .padding(.bottom, 20),  // increased bottom padding for extra room
                alignment: .bottom
            )
        }
        .onAppear {
            print("[VideoCellView] onAppear => setupPlayer => video \(video.id), index=\(index).")
            setupPlayer()
        }
        .onDisappear {
            print("[VideoCellView] onDisappear => cleanupPlayer => video \(video.id), index=\(index).")
            cleanupPlayer()
        }
        .onChange(of: activePage) { newValue in
            if newValue != index {
                player?.pause()
                print("[VideoCellView] onChange(of: activePage) => pausing video \(video.id). newValue=\(newValue).")
            } else {
                if let p = player, p.rate == 0 {
                    p.play()
                    print("[VideoCellView] onChange => playing video \(video.id). newValue=\(newValue).")
                }
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(videoID: video.id)
                .presentationDetents([.fraction(0.85)])
                .presentationDragIndicator(.visible)
        }
    }

    private func togglePlayback() {
        guard let player = player else { return }
        if player.rate == 0 {
            player.play()
            print("[VideoCellView] togglePlayback => playing video \(video.id).")
        } else {
            player.pause()
            print("[VideoCellView] togglePlayback => paused video \(video.id).")
        }
    }

    private func setupPlayer() {
        let startTime = Date()
        print("[VideoCellView] setupPlayer => started at \(startTime). VideoID=\(video.id)")
        
        // Listen for comment updates.
        _ = db.collection("videos").document(video.id)
            .collection("comments")
            .addSnapshotListener { snapshot, _ in
                commentsCount = snapshot?.documents.count ?? 0
                print("[VideoCellView] Comments updated => count=\(commentsCount). VideoID=\(video.id)")
            }
        
        if let preloaded = preloadedPlayer {
            playerError = nil
            isLoading = false
            player = preloaded
            let elapsed = Date().timeIntervalSince(startTime)
            print("[VideoCellView] Using preloaded player => video \(video.id), load time=\(elapsed)s.")
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
                            print("[VideoCellView] Key='\(key)' => status=\(status.rawValue). VideoID=\(self.video.id)")
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
                                    print("[VideoCellView] FailedToPlayToEnd => \(err). VideoID=\(self.video.id)")
                                }
                            }
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: item,
                                queue: .main
                            ) { _ in
                                newPlayer.seek(to: .zero)
                                newPlayer.play()
                                print("[VideoCellView] Video ended => looping video \(self.video.id).")
                            }
                            
                            self.player = newPlayer
                            self.isLoading = false
                            print("[VideoCellView] Fallback loaded => success => video \(self.video.id).")
                        } else {
                            self.isLoading = false
                            print("[VideoCellView] Fallback load => failed => video \(self.video.id).")
                        }
                        
                        let elapsed = Date().timeIntervalSince(startTime)
                        print("[VideoCellView] setupPlayer done => took \(elapsed)s => video \(self.video.id).")
                    }
                }
            }
        }
    }

    private func cleanupPlayer() {
        print("[VideoCellView] cleanupPlayer => video \(video.id).")
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
                                print("[BottomOverlayView] Expanding caption => video \(video.id)")
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
                                    print("[BottomOverlayView] Collapsing caption => video \(video.id)")
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            } else {
                                HStack {
                                    Button("Show More") {
                                        withAnimation { isCaptionFullyExpanded = true }
                                        print("[BottomOverlayView] Fully expanding => video \(video.id)")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    
                                    Button("Show Less") {
                                        withAnimation {
                                            isCaptionExpanded = false
                                            isCaptionFullyExpanded = false
                                        }
                                        print("[BottomOverlayView] Collapsing caption => video \(video.id)")
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
                                print("[BottomOverlayView] Collapsing caption => video \(video.id)")
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
                // Add extra bottom padding here so the date isn’t clipped.
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
