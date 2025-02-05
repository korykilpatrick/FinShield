import Foundation
import FirebaseFirestore
import AVFoundation

class VideoFeedViewModel: ObservableObject {
    @Published var videos: [Video] = []
    
    private let db = Firestore.firestore()
    private var preloadedItems: [Int: AVPlayerItem] = [:]
    private var preloadedPlayers: [Int: AVPlayer] = [:]
    
    init() {
        fetchVideos()
    }
    
    func fetchVideos() {
        // Listen for all video docs
        db.collection("videos").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("[\(Date())] Error fetching videos: \(error.localizedDescription)")
                return
            }
            guard let docs = snapshot?.documents else { return }
            let fetched = docs.compactMap { Video(from: $0.data(), id: $0.documentID) }
            // Filter to only include HLS videos by ensuring the URL contains "master.m3u8"
            self.videos = fetched.filter { $0.videoURL.absoluteString.contains("master.m3u8") }.shuffled()
            print("[\(Date())] Fetched \(self.videos.count) HLS videos")
            
            // Clear preloads each time the list changes
            self.preloadedItems.removeAll()
            self.preloadedPlayers.removeAll()
        }
    }
    
    func preloadVideo(at index: Int) {
        guard index >= 0, index < videos.count else { return }
        if preloadedItems[index] != nil { return }

        let videoURL = videos[index].videoURL
        let asset = AVURLAsset(url: videoURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let keys = ["playable", "duration", "preferredTransform"]
        let startTime = Date()
        
        print("[\(startTime)] Preload => index \(index)")
        
        DispatchQueue.global(qos: .background).async {
            asset.loadValuesAsynchronously(forKeys: keys) {
                var allLoaded = true
                for key in keys {
                    var error: NSError?
                    let status = asset.statusOfValue(forKey: key, error: &error)
                    if status != .loaded { allLoaded = false; break }
                }
                DispatchQueue.main.async {
                    if allLoaded {
                        let item = AVPlayerItem(asset: asset)
                        item.preferredForwardBufferDuration = 5.0
                        // Removed forced peak bitrate to enable ABR:
                        // item.preferredPeakBitRate = 500_000
                        let player = AVPlayer(playerItem: item)
                        player.actionAtItemEnd = .none
                        player.automaticallyWaitsToMinimizeStalling = true
                        
                        self.preloadedItems[index] = item
                        self.preloadedPlayers[index] = player
                        let totalElapsed = Date().timeIntervalSince(startTime)
                        print("[\(Date())] Preload success => index \(index), elapsed: \(totalElapsed)s")
                        
                        // Cleanup older entries
                        self.cleanupOldPreloadedAssets(keepingIndex: index)
                    } else {
                        print("[\(Date())] Preload fail => index \(index)")
                    }
                }
            }
        }
    }
    
    func getPreloadedItem(for index: Int) -> AVPlayerItem? {
        preloadedItems[index]
    }
    
    func getPreloadedPlayer(for index: Int) -> AVPlayer? {
        preloadedPlayers[index]
    }
    
    private func cleanupOldPreloadedAssets(keepingIndex current: Int) {
        let low = max(0, current - 2)
        let high = min(videos.count - 1, current + 2)
        
        preloadedItems = preloadedItems.filter { key, _ in (low...high).contains(key) }
        preloadedPlayers = preloadedPlayers.filter { key, _ in (low...high).contains(key) }
        
        print("[\(Date())] cleanup => keeping indices \(low)...\(high)")
    }
}