import Foundation
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

class FirebaseService {
    static let shared = FirebaseService()
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    func uploadVideo(fileURL: URL, caption: String, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let videoID = UUID().uuidString
        let storageRef = storage.reference().child("videos/\(videoID).mp4")
        
        storageRef.putFile(from: fileURL, metadata: nil) { metadata, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                completion(false)
                return
            }
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Download URL error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                guard let downloadURL = url else {
                    completion(false)
                    return
                }
                let videoData: [String: Any] = [
                    "videoURL": downloadURL.absoluteString,
                    "caption": caption,
                    "uid": uid,
                    "timestamp": FieldValue.serverTimestamp()
                ]
                self.db.collection("videos").document(videoID).setData(videoData) { error in
                    if let error = error {
                        print("Error saving metadata: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }
}
