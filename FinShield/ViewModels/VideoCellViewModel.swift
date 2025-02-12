import SwiftUI
import FirebaseFirestore

class VideoCellViewModel: ObservableObject, Identifiable {
    @Published var video: Video
    @Published var factCheckResults: [FactCheckResult] = []
    
    private let db = Firestore.firestore()
    
    init(video: Video) {
        self.video = video
        fetchFactCheckResults()
    }
    
    private func fetchFactCheckResults() {
        guard video.status == "processed" else { return }
        let factCheckRef = db.collection("videos").document(video.id).collection("fact_check_results")
        factCheckRef.getDocuments { [weak self] snapshot, error in
            guard let self = self, let snap = snapshot else { return }
            var results: [FactCheckResult] = []
            let group = DispatchGroup()
            for doc in snap.documents {
                guard let data = doc.data() as? [String: Any],
                      let claimText = data["claim_text"] as? String,
                      let sStart = data["start_time"] as? String,
                      let sEnd = data["end_time"] as? String
                else { continue }
                
                let startSecs = parseSRTTime(sStart)
                let endSecs = parseSRTTime(sEnd)
                let factCheckID = doc.documentID
                
                group.enter()
                let sourcesRef = factCheckRef.document(factCheckID).collection("sources")
                sourcesRef.getDocuments { sourceSnap, _ in
                    var sourceList: [FactCheckSource] = []
                    if let sourceSnap = sourceSnap {
                        for sDoc in sourceSnap.documents {
                            let sData = sDoc.data()
                            let confidence = sData["confidence"] as? Double ?? 0
                            let explanation = sData["explanation"] as? String ?? ""
                            let links = sData["reference_links"] as? [String] ?? []
                            let name = sData["source_name"] as? String ?? ""
                            let type = sData["type"] as? String ?? ""
                            let verification = sData["verification"] as? String ?? ""
                            
                            sourceList.append(
                                FactCheckSource(
                                    id: sDoc.documentID,
                                    confidence: confidence,
                                    explanation: explanation,
                                    referenceLinks: links,
                                    sourceName: name,
                                    type: type,
                                    verification: verification
                                )
                            )
                        }
                    }
                    let fcResult = FactCheckResult(
                        id: factCheckID,
                        claimText: claimText,
                        startTime: startSecs,
                        endTime: endSecs,
                        sources: sourceList
                    )
                    results.append(fcResult)
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                self.factCheckResults = results
            }
        }
    }
}
