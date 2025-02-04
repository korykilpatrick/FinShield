import Foundation

class VideoEditingService {
    static let shared = VideoEditingService()
    
    func trimVideo(videoURL: URL, startTime: Double, endTime: Double, completion: @escaping (URL?) -> Void) {
        // Replace with your actual OpenShot API endpoint.
        guard let endpoint = URL(string: "https://your-openshot-api-endpoint/trim") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        let payload: [String: Any] = [
            "videoURL": videoURL.absoluteString,
            "startTime": startTime,
            "endTime": endTime
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Video editing error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let trimmedURLString = json["trimmedVideoURL"] as? String,
                  let trimmedURL = URL(string: trimmedURLString) else {
                completion(nil)
                return
            }
            completion(trimmedURL)
        }.resume()
    }
}
