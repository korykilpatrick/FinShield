import Foundation
import FirebaseFirestore

struct Comment: Identifiable {
    let id: String
    let uid: String
    let text: String
    let timestamp: Date
    
    init?(from dict: [String: Any], id: String) {
        guard let uid = dict["uid"] as? String,
              let text = dict["text"] as? String,
              let timestamp = dict["timestamp"] as? Timestamp else {
            return nil
        }
        self.id = id
        self.uid = uid
        self.text = text
        self.timestamp = timestamp.dateValue()
    }
}
