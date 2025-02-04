import Foundation
import FirebaseFirestore
import FirebaseAuth

class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    private var db = Firestore.firestore()
    private var videoID: String
    
    init(videoID: String) {
        self.videoID = videoID
        fetchComments()
    }
    
    func fetchComments() {
        db.collection("videos").document(videoID)
            .collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching comments: \(error.localizedDescription)")
                    return
                }
                guard let docs = snapshot?.documents else { return }
                self?.comments = docs.compactMap { doc in
                    return Comment(from: doc.data(), id: doc.documentID)
                }
            }
    }
    
    func addComment(text: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let data: [String: Any] = [
            "uid": uid,
            "text": text,
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("videos").document(videoID)
            .collection("comments")
            .addDocument(data: data) { error in
                if let error = error {
                    print("Error adding comment: \(error.localizedDescription)")
                }
            }
    }
}
