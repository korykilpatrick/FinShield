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
        print("[CommentsViewModel] init => videoID=\(videoID)")
        self.videoID = videoID
        fetchComments()
    }
    
    deinit {
        listenerRegistration?.remove()
        print("[CommentsViewModel] deinit => removed listener for videoID=\(videoID)")
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
                    print("[CommentsViewModel] Error => \(error.localizedDescription)")
                    return
                }
                
                guard let docs = snapshot?.documents else { return }
                
                self.comments = docs.compactMap { doc in
                    Comment(from: doc.data(), id: doc.documentID)
                }
                print("[CommentsViewModel] Updated => #comments=\(self.comments.count)")
            }
    }
    
    func addComment(text: String) {
        guard let currentUser = Auth.auth().currentUser else {
            self.error = "You must be signed in to comment"
            print("[CommentsViewModel] addComment => user not signed in.")
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
                    print("[CommentsViewModel] addComment => error=\(error.localizedDescription)")
                } else {
                    print("[CommentsViewModel] addComment => success, text=\(text)")
                }
            }
    }
    
    func deleteComment(_ comment: Comment) {
        guard let currentUser = Auth.auth().currentUser,
              currentUser.uid == comment.uid else {
            self.error = "You can only delete your own comments"
            print("[CommentsViewModel] deleteComment => not authorized.")
            return
        }
        
        db.collection("videos").document(videoID)
            .collection("comments")
            .document(comment.id)
            .delete { [weak self] error in
                if let error = error {
                    self?.error = error.localizedDescription
                    print("[CommentsViewModel] deleteComment => error=\(error.localizedDescription)")
                } else {
                    print("[CommentsViewModel] deleteComment => success.")
                }
            }
    }
    
    func clearError() {
        error = nil
    }
}
