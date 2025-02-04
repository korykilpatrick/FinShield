import Foundation
import FirebaseFirestore

class VideoFeedViewModel: ObservableObject {
    @Published var videos: [Video] = []
    private var db = Firestore.firestore()
    
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
                return Video(from: doc.data(), id: doc.documentID)
            }
            self?.videos = vids.shuffled()
        }
    }
}
