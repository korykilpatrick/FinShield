import Foundation
import FirebaseFirestore
import AVFoundation

class VideoFeedViewModel: ObservableObject {
    @Published var videos: [Video] = []
    private var db = Firestore.firestore()
    private var preloadedAssets: [Int: AVAsset] = [:]
    
    init() {
        fetchVideos()
    }
    
    func fetchVideos() {
        db.collection("videos").addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching videos: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            let vids = documents.compactMap { doc in
                return Video(from: doc.data(), id: doc.documentID)
            }
            self?.videos = vids.shuffled()
        }
    }
    
    func preloadVideo(at index: Int) {
        guard index < videos.count else { return }
        
        let video = videos[index]
        if preloadedAssets[index] == nil {
            let asset = AVAsset(url: video.videoURL)
            preloadedAssets[index] = asset
            
            // Preload key data needed for playback
            let keys = ["playable", "duration"]
            asset.loadValuesAsynchronously(forKeys: keys) {
                // Clear older preloaded assets to manage memory
                self.cleanupOldPreloadedAssets(keepingIndex: index)
            }
        }
    }
    
    private func cleanupOldPreloadedAssets(keepingIndex currentIndex: Int) {
        let keepRange = max(0, currentIndex - 1)...min(videos.count - 1, currentIndex + 1)
        preloadedAssets = preloadedAssets.filter { keepRange.contains($0.key) }
    }
}
