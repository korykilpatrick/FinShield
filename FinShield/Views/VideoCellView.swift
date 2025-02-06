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
    @State private var commentsListener: ListenerRegistration?
    
    @State private var isCaptionExpanded = false
    @State private var isCaptionFullyExpanded = false
    
    private let db = Firestore.firestore()
    
    init(video: Video, preloadedPlayer: AVPlayer?, index: Int, activePage: Binding<Int>) {
        self.video = video
        self.preloadedPlayer = preloadedPlayer
        self.index = index
        self._activePage = activePage
        _likesCount = State(initialValue: video.numLikes)
        _bookmarksCount = State(initialValue: video.numBookmarks)
        _sharesCount = State(initialValue: video.numShares)
    }
    
    private var displayedCaption: String {
        if !isCaptionExpanded {
            return video.caption.count > 50 ? String(video.caption.prefix(50)) + "..." : video.caption
        } else if !isCaptionFullyExpanded {
            return video.caption.count > 200 ? String(video.caption.prefix(200)) + "..." : video.caption
        } else {
            return video.caption
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    Group {
                        if let player = player {
                            CustomVideoPlayer(player: player)
                                .onAppear {
                                    print("[VideoCellView] onAppear: Starting video \(video.id)")
                                    // Only auto-play if this is the active page.
                                    if activePage == index { player.play() }
                                }
                                .onDisappear {
                                    print("[VideoCellView] onDisappear: Pausing video \(video.id)")
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
                    .zIndex(0)
                    
                    // Overlay tap-to-toggle using a simultaneous gesture.
                    Color.clear
                        .contentShape(Rectangle())
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    if abs(value.translation.width) < 10 && abs(value.translation.height) < 10 {
                                        if let player = player {
                                            if player.rate == 0 {
                                                player.play()
                                                print("[VideoCellView] Player toggled to play.")
                                            } else {
                                                player.pause()
                                                print("[VideoCellView] Player toggled to pause.")
                                            }
                                        } else {
                                            print("[VideoCellView] No player available on tap.")
                                        }
                                    }
                                }
                        )
                        .zIndex(999)
                }
                
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
                    .onAppear {
                        print("[VideoCellView] Error for video \(video.id): \(error.localizedDescription)")
                    }
                }
                
                VStack {
                    Spacer()
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
                                            print("[VideoCellView] Expanding caption for video \(video.id)")
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
                                                print("[VideoCellView] Collapsing caption for video \(video.id)")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        } else {
                                            HStack {
                                                Button("Show More") {
                                                    withAnimation { isCaptionFullyExpanded = true }
                                                    print("[VideoCellView] Fully expanding caption for video \(video.id)")
                                                }
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                                
                                                Button("Show Less") {
                                                    withAnimation {
                                                        isCaptionExpanded = false
                                                        isCaptionFullyExpanded = false
                                                    }
                                                    print("[VideoCellView] Collapsing caption for video \(video.id)")
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
                                            print("[VideoCellView] Collapsing caption for video \(video.id)")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            Text(DateUtils.formattedDate(from: video.timestamp))
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        .padding(.leading)
                        .padding(.bottom, 20)
                        
                        Spacer()
                        
                        VideoSidebarView(
                            numLikes: likesCount,
                            numComments: commentsCount,
                            numBookmarks: bookmarksCount,
                            numShares: sharesCount,
                            isLiked: isLiked,
                            isBookmarked: isBookmarked,
                            onLike: {
                                isLiked.toggle()
                                likesCount += isLiked ? 1 : -1
                                print("[VideoCellView] Like toggled => isLiked=\(isLiked), total=\(likesCount)")
                            },
                            onBookmark: {
                                isBookmarked.toggle()
                                bookmarksCount += isBookmarked ? 1 : -1
                                print("[VideoCellView] Bookmark toggled => isBookmarked=\(isBookmarked), total=\(bookmarksCount)")
                            },
                            onComment: {
                                showComments = true
                                print("[VideoCellView] Comment tapped => showing comments for video \(video.id)")
                            }
                        )
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
                .zIndex(3)
            }
        }
        .onAppear {
            print("[VideoCellView] onAppear => setupPlayer() for video \(video.id)")
            setupPlayer()
        }
        .onDisappear {
            print("[VideoCellView] onDisappear => cleanupPlayer() for video \(video.id)")
            cleanupPlayer()
        }
        // When the active page changes, pause this video if it’s not current,
        // or play it if it just became active.
        .onChange(of: activePage) { newValue in
            if newValue != index {
                player?.pause()
                print("[VideoCellView] Pausing video \(video.id) because activePage changed to \(newValue)")
            } else {
                if let player = player, player.rate == 0 {
                    player.play()
                    print("[VideoCellView] Playing video \(video.id) because activePage is now \(newValue)")
                }
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(videoID: video.id)
                .presentationDetents([.fraction(0.85)])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func setupPlayer() {
        let startTime = Date()
        print("[VideoCellView] setupPlayer called at \(startTime) for video \(video.id)")
        
        commentsListener = db.collection("videos").document(video.id)
            .collection("comments")
            .addSnapshotListener { snapshot, _ in
                commentsCount = snapshot?.documents.count ?? 0
                print("[VideoCellView] Comments updated => \(commentsCount) for video \(video.id)")
            }
        
        if let preloaded = preloadedPlayer {
            playerError = nil
            isLoading = false
            player = preloaded
            let elapsed = Date().timeIntervalSince(startTime)
            print("[VideoCellView] Using preloaded player => video \(video.id), \(elapsed)s")
        } else {
            isLoading = true
            DispatchQueue.global(qos: .background).async {
                let asset = AVURLAsset(url: self.video.videoURL,
                                       options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
                let keys = ["playable", "preferredTransform"]
                
                asset.loadValuesAsynchronously(forKeys: keys) {
                    DispatchQueue.main.async {
                        var allLoaded = true
                        for key in keys {
                            var error: NSError?
                            let status = asset.statusOfValue(forKey: key, error: &error)
                            print("[VideoCellView] Key '\(key)' loaded => status=\(status.rawValue)")
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
                                    print("[VideoCellView] AVPlayerItemFailedToPlayToEndTime => \(err)")
                                }
                            }
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: item,
                                queue: .main
                            ) { _ in
                                newPlayer.seek(to: .zero)
                                newPlayer.play()
                                print("[VideoCellView] Video ended => restarting \(self.video.id).")
                            }
                            
                            self.player = newPlayer
                            self.isLoading = false
                            print("[VideoCellView] Asset loaded => fallback success for video \(self.video.id)")
                        } else {
                            self.isLoading = false
                            print("[VideoCellView] Fallback load failed => video \(self.video.id)")
                        }
                        let elapsed = Date().timeIntervalSince(startTime)
                        print("[VideoCellView] setupPlayer done => \(elapsed)s for video \(self.video.id)")
                    }
                }
            }
        }
    }
    
    private func cleanupPlayer() {
        print("[VideoCellView] cleanupPlayer => \(video.id)")
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        NotificationCenter.default.removeObserver(self)
        commentsListener?.remove()
        player = nil
        isLoading = false
    }
}
