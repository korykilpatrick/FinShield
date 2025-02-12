import Foundation
import FirebaseFirestore
import AVFoundation

class VideoFeedViewModel: ObservableObject {
    @Published var videos: [Video] = []
    
    private let db = Firestore.firestore()
    private var preloadedItems: [Int: AVPlayerItem] = [:]
    private var preloadedPlayers: [Int: AVPlayer] = [:]
    
    init() {
        print("[VideoFeedViewModel] init => fetching videos.")
        fetchVideos()
    }
    
    func fetchVideos() {
        // Listen for changes in the 'videos' collection
        db.collection("videos").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("[VideoFeedViewModel] Error fetching videos: \(error.localizedDescription)")
                return
            }
            guard let docs = snapshot?.documents else {
                print("[VideoFeedViewModel] No documents found.")
                return
            }
            
            let fetched = docs.compactMap {
                Video(from: $0.data(), id: $0.documentID)
            }
            // Keep only .m3u8 (HLS) videos, shuffle them
            self.videos = fetched.filter {
                $0.videoURL.absoluteString.contains("master.m3u8")
            }.shuffled()
            
            print("[VideoFeedViewModel] Fetched \(self.videos.count) HLS videos.")
            
            // Clear preloaded once we get a fresh batch
            self.preloadedItems.removeAll()
            self.preloadedPlayers.removeAll()
            
            // Now fetch fact-check results for each processed video
            self.fetchFactCheckResults()
        }
    }
    
    private func fetchFactCheckResults() {
        // For each video that has status == "processed", get the subcollection fact_check_results
        for index in videos.indices {
            if videos[index].status == "processed" {
                let videoID = videos[index].id
                let factCheckRef = db.collection("videos")
                    .document(videoID)
                    .collection("fact_check_results")
                
                factCheckRef.getDocuments { [weak self] snap, err in
                    guard let self = self, let snap = snap else { return }
                    
                    var results: [FactCheckResult] = []
                    let group = DispatchGroup()
                    
                    for doc in snap.documents {
                        let data = doc.data()
                        
                        guard
                            let claimText = data["claim_text"] as? String,
                            let sStart = data["start_time"] as? String,
                            let sEnd = data["end_time"] as? String
                        else { continue }
                        
                        let startSecs = parseSRTTime(sStart)
                        let endSecs = parseSRTTime(sEnd)
                        let factCheckID = doc.documentID
                        // log what we have so far
                        print("[VideoFeedViewModel 78] Fact check results for video \(videoID): \(results)")
                        
                        // For each claim doc, fetch its sources
                        let sourcesRef = factCheckRef.document(factCheckID).collection("sources")
                        group.enter()
                        sourcesRef.getDocuments { sourceSnap, _ in
                            var sourceList: [FactCheckSource] = []
                            
                            if let sourceSnap = sourceSnap {
                                for sDoc in sourceSnap.documents {
                                    let sData = sDoc.data()
                                    let sourceID = sDoc.documentID
                                    
                                    let confidence = sData["confidence"] as? Double ?? 0
                                    let explanation = sData["explanation"] as? String ?? ""
                                    let links = sData["reference_links"] as? [String] ?? []
                                    let name = sData["source_name"] as? String ?? ""
                                    let type = sData["type"] as? String ?? ""
                                    let verification = sData["verification"] as? String ?? ""
                                    
                                    sourceList.append(
                                        FactCheckSource(
                                            id: sourceID,
                                            confidence: confidence,
                                            explanation: explanation,
                                            referenceLinks: links,
                                            sourceName: name,
                                            type: type,
                                            verification: verification
                                        )
                                    )
                                }
                            }
                            
                            let fcResult = FactCheckResult(
                                id: factCheckID,
                                claimText: claimText,
                                startTime: startSecs,
                                endTime: endSecs,
                                sources: sourceList
                            )
                            print("[VideoFeedViewModel 119] Fact check result: \(fcResult)")
                            results.append(fcResult)
                            group.leave()
                        }
                    }
                    
                    // Once all subcollection fetches finish, update the video
                    group.notify(queue: .main) {
                        if let vidIndex = self.videos.firstIndex(where: { $0.id == videoID }) {
                            self.videos[vidIndex].factCheckResults = results
                        }
                    }
                }
            }
        }
    }
    
    // Video preloading (unchanged)
    func preloadVideo(at index: Int) {
        guard index >= 0, index < videos.count else { return }
        if preloadedItems[index] != nil { return }
        
        let videoURL = videos[index].videoURL
        let asset = AVURLAsset(url: videoURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let keys = ["playable", "duration", "preferredTransform"]
        let startTime = Date()
        
        print("[VideoFeedViewModel] Preloading index \(index), URL: \(videoURL).")
        
        DispatchQueue.global(qos: .background).async {
            asset.loadValuesAsynchronously(forKeys: keys) {
                var allLoaded = true
                for key in keys {
                    var error: NSError?
                    let status = asset.statusOfValue(forKey: key, error: &error)
                    if status != .loaded {
                        allLoaded = false
                        print("[VideoFeedViewModel] Preload => Key \(key) not loaded.")
                        break
                    }
                }
                DispatchQueue.main.async {
                    if allLoaded {
                        let item = AVPlayerItem(asset: asset)
                        item.preferredForwardBufferDuration = 5.0
                        let player = AVPlayer(playerItem: item)
                        player.actionAtItemEnd = .none
                        player.automaticallyWaitsToMinimizeStalling = true
                        
                        self.preloadedItems[index] = item
                        self.preloadedPlayers[index] = player
                        
                        let totalElapsed = Date().timeIntervalSince(startTime)
                        print("[VideoFeedViewModel] Preload success => index \(index), elapsed: \(totalElapsed)s.")
                        
                        self.cleanupOldPreloadedAssets(keepingIndex: index)
                    } else {
                        print("[VideoFeedViewModel] Preload fail => index \(index).")
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
        preloadedItems = preloadedItems.filter { (key, _) in (low...high).contains(key) }
        preloadedPlayers = preloadedPlayers.filter { (key, _) in (low...high).contains(key) }
        
        print("[VideoFeedViewModel] cleanup => keeping indices \(low) to \(high).")
    }
}
