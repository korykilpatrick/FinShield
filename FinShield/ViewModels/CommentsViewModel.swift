import Foundation
import FirebaseFirestore
import FirebaseAuth

class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var db = Firestore.firestore()
    private var videoID: String
    private var listenerRegistration: ListenerRegistration?
    
    init(videoID: String) {
        self.videoID = videoID
        fetchComments()
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func fetchComments() {
        isLoading = true
        error = nil
        
        listenerRegistration = db.collection("videos").document(videoID)
            .collection("comments")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let docs = snapshot?.documents else { return }
                self.comments = docs.compactMap { doc in
                    return Comment(from: doc.data(), id: doc.documentID)
                }
            }
    }
    
    func addComment(text: String) {
        guard let currentUser = Auth.auth().currentUser else {
            self.error = "You must be signed in to comment"
            return
        }
        
        let data: [String: Any] = [
            "uid": currentUser.uid,
            "username": currentUser.displayName ?? "Anonymous",
            "text": text,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("videos").document(videoID)
            .collection("comments")
            .addDocument(data: data) { [weak self] error in
                if let error = error {
                    self?.error = error.localizedDescription
                }
            }
    }
    
    func deleteComment(_ comment: Comment) {
        guard let currentUser = Auth.auth().currentUser,
              currentUser.uid == comment.uid else {
            self.error = "You can only delete your own comments"
            return
        }
        
        db.collection("videos").document(videoID)
            .collection("comments")
            .document(comment.id)
            .delete { [weak self] error in
                if let error = error {
                    self?.error = error.localizedDescription
                }
            }
    }
    
    func clearError() {
        error = nil
    }
}
