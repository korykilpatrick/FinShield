import Foundation
import FirebaseFirestore

// MARK: - Fact Check Models
struct FactCheckSource: Identifiable, Equatable {
    let id: String
    let confidence: Double
    let explanation: String
    let referenceLinks: [String]
    let sourceName: String
    let type: String
    let verification: String
}

struct FactCheckResult: Identifiable, Equatable {
    let id: String
    let claimText: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let sources: [FactCheckSource]
}

// MARK: - Video Model
struct Video: Identifiable, Equatable {
    let id: String
    let videoName: String
    let videoTitle: String
    let videoURL: URL
    let caption: String
    let username: String
    let timestamp: Date
    let profilePicture: URL?
    let numLikes: Int
    let numBookmarks: Int
    let numShares: Int
    
    // New fields for fact-check integration
    var status: String
    var factCheckResults: [FactCheckResult]
    
    init?(from dict: [String: Any], id: String) {
        guard
            let urlString = dict["videoURL"] as? String,
            urlString.contains("master.m3u8"),
            let url = URL(string: urlString),
            let caption = dict["caption"] as? String,
            let videoName = dict["videoName"] as? String,
            let videoTitle = dict["videoTitle"] as? String,
            let username = dict["username"] as? String,
            let ts = dict["timestamp"] as? Timestamp
        else {
            print("[Video Model] Failed to init from dict => \(dict)")
            return nil
        }
        
        self.id = id
        self.videoName = videoName
        self.videoTitle = videoTitle
        self.videoURL = url
        self.caption = caption
        self.username = username
        self.timestamp = ts.dateValue()
        
        if let profileString = dict["profilePicture"] as? String,
           let profileURL = URL(string: profileString) {
            self.profilePicture = profileURL
        } else {
            self.profilePicture = nil
        }
        
        self.numLikes = dict["numLikes"] as? Int ?? 0
        self.numBookmarks = dict["numBookmarks"] as? Int ?? 0
        self.numShares = dict["numShares"] as? Int ?? 0
        
        // If missing status, treat as "pending"
        self.status = dict["status"] as? String ?? "pending"
        
        // We won't parse factCheckResults in init; the view model does it after a second fetch
        self.factCheckResults = []
    }
}