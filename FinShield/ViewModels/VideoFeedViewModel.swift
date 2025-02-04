import Foundation
import FirebaseFirestore
import AVFoundation

// VideoFeedViewModel
class VideoFeedViewModel: ObservableObject {
    @Published var videos: [Video] = []
    private var db = Firestore.firestore()
    private var preloadedAssets: [Int: AVAsset] = [:]

    init() { fetchVideos() }

    func fetchVideos() {
        db.collection("videos").addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching videos: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            let vids = documents.compactMap { doc in
                Video(from: doc.data(), id: doc.documentID)
            }
            self?.videos = vids.shuffled()
        }
    }

    func preloadVideo(at index: Int) {
        guard index >= 0, index < videos.count else { return }
        if preloadedAssets[index] == nil {
            let asset = AVAsset(url: videos[index].videoURL)
            preloadedAssets[index] = asset
            let keys = ["playable", "duration"]
            asset.loadValuesAsynchronously(forKeys: keys) {
                self.cleanupOldPreloadedAssets(keepingIndex: index)
            }
        }
    }

    private func cleanupOldPreloadedAssets(keepingIndex currentIndex: Int) {
        let range = max(0, currentIndex - 1)...min(videos.count - 1, currentIndex + 1)
        preloadedAssets = preloadedAssets.filter { range.contains($0.key) }
    }
}