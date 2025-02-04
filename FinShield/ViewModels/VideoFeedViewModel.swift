import Foundation
import FirebaseFirestore
import AVFoundation

class VideoFeedViewModel: ObservableObject {
    @Published var videos: [Video] = []
    private var db = Firestore.firestore()
    // Caches for preloaded player items and players.
    private var preloadedItems: [Int: AVPlayerItem] = [:]
    private var preloadedPlayers: [Int: AVPlayer] = [:]
    
    init() {
        fetchVideos()
    }
    
    func fetchVideos() {
        db.collection("videos").addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("[\(Date())] Error fetching videos: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            let vids = documents.compactMap { doc in
                Video(from: doc.data(), id: doc.documentID)
            }
            self?.videos = vids.shuffled()
            print("[\(Date())] Fetched \(vids.count) videos")
        }
    }
    
    func preloadVideo(at index: Int) {
        guard index >= 0, index < videos.count else { return }
        if preloadedItems[index] != nil { return }
        
        let videoURL = videos[index].videoURL
        let asset = AVURLAsset(url: videoURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let keys = ["playable", "duration", "preferredTransform"]
        let preloadStartTime = Date()
        print("[\(preloadStartTime)] Start preloading asset for index \(index)")
        
        asset.loadValuesAsynchronously(forKeys: keys) { [weak self] in
            guard let self = self else { return }
            for key in keys {
                var error: NSError?
                let status = asset.statusOfValue(forKey: key, error: &error)
                let keyLoadedTime = Date()
                let elapsed = keyLoadedTime.timeIntervalSince(preloadStartTime)
                print("[\(keyLoadedTime)] Loaded key '\(key)' for index \(index), elapsed: \(elapsed)s")
                if status != .loaded {
                    print("[\(Date())] Failed to load key \(key) for asset \(videoURL.absoluteString) at index \(index): \(error?.localizedDescription ?? "unknown error")")
                    return
                }
            }
            DispatchQueue.main.async {
                let item = AVPlayerItem(asset: asset)
                item.preferredForwardBufferDuration = 5.0
                item.preferredPeakBitRate = 500_000
                self.preloadedItems[index] = item
                let player = AVPlayer(playerItem: item)
                player.actionAtItemEnd = .none
                player.automaticallyWaitsToMinimizeStalling = true
                self.preloadedPlayers[index] = player
                let preloadEndTime = Date()
                let totalElapsed = preloadEndTime.timeIntervalSince(preloadStartTime)
                print("[\(preloadEndTime)] Preloading complete for index \(index), total elapsed: \(totalElapsed)s")
                self.cleanupOldPreloadedAssets(keepingIndex: index)
            }
        }
    }
    
    func getPreloadedItem(for index: Int) -> AVPlayerItem? {
        return preloadedItems[index]
    }
    
    func getPreloadedPlayer(for index: Int) -> AVPlayer? {
        return preloadedPlayers[index]
    }
    
    private func cleanupOldPreloadedAssets(keepingIndex currentIndex: Int) {
        let low = max(0, currentIndex - 2)
        let high = min(videos.count - 1, currentIndex + 2)
        preloadedItems = preloadedItems.filter { key, _ in key >= low && key <= high }
        preloadedPlayers = preloadedPlayers.filter { key, _ in key >= low && key <= high }
        print("[\(Date())] Cleaned up caches; keeping indices \(low) to \(high)")
    }
}
