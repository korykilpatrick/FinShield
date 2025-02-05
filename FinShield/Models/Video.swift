import Foundation

struct Video: Identifiable, Equatable {
    let id: String
    let videoURL: URL
    let caption: String
    
    init?(from dict: [String: Any], id: String) {
        guard let urlString = dict["videoURL"] as? String,
              // Only accept URLs that refer to the HLS master manifest
              urlString.contains("master.m3u8"),
              let url = URL(string: urlString),
              let caption = dict["caption"] as? String else {
            return nil
        }
        self.id = id
        self.videoURL = url
        self.caption = caption
    }
}