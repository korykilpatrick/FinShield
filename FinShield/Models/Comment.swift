import Foundation
import FirebaseFirestore

struct Comment: Identifiable {
    let id: String
    let uid: String
    let username: String
    let text: String
    let timestamp: Date
    
    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    init?(from dict: [String: Any], id: String) {
        guard let uid = dict["uid"] as? String,
              let username = dict["username"] as? String,
              let text = dict["text"] as? String,
              let timestamp = dict["timestamp"] as? Timestamp else {
            return nil
        }
        self.id = id
        self.uid = uid
        self.username = username
        self.text = text
        self.timestamp = timestamp.dateValue()
    }
}
