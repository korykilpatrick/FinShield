import Foundation

struct Video: Identifiable {
    let id: String
    let videoURL: URL
    let caption: String
    // You can add uploader UID, timestamp, etc.
    
    init?(from dict: [String: Any], id: String) {
        guard let urlString = dict["videoURL"] as? String,
              let url = URL(string: urlString),
              let caption = dict["caption"] as? String else {
            return nil
        }
        self.id = id
        self.videoURL = url
        self.caption = caption
    }
}
