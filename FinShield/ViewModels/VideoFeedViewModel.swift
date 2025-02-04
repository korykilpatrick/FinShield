//
//  VideoFeedViewModel.swift
//  FinShield
//

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
        if preloadedItems[index] == nil {
            let videoURL = videos[index].videoURL
            let asset = AVURLAsset(url: videoURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
            // Preload keys including "preferredTransform" to avoid main-thread blocking later.
            let keys = ["playable", "duration", "preferredTransform"]
            asset.loadValuesAsynchronously(forKeys: keys) {
                // Ensure each key is loaded.
                for key in keys {
                    var error: NSError?
                    let status = asset.statusOfValue(forKey: key, error: &error)
                    if status != .loaded {
                        print("Failed to load key \(key) for asset \(videoURL): \(error?.localizedDescription ?? "unknown error")")
                        return
                    }
                }
                // All keys loaded—create an AVPlayerItem and cache it on the main thread.
                DispatchQueue.main.async {
                    let item = AVPlayerItem(asset: asset)
                    item.preferredForwardBufferDuration = 5.0
                    self.preloadedItems[index] = item
                    // Create and cache a reusable AVPlayer instance.
                    let player = AVPlayer(playerItem: item)
                    player.actionAtItemEnd = .none
                    self.preloadedPlayers[index] = player
                    self.cleanupOldPreloadedAssets(keepingIndex: index)
                }
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
        // Keep a window of five videos: current, two before, and two after.
        let low = max(0, currentIndex - 2)
        let high = min(videos.count - 1, currentIndex + 2)
        preloadedItems = preloadedItems.filter { key, _ in key >= low && key <= high }
        preloadedPlayers = preloadedPlayers.filter { key, _ in key >= low && key <= high }
    }
}
