import SwiftUI

struct CommentsView: View {
    let videoID: String
    @StateObject var viewModel: CommentsViewModel
    @State private var commentText: String = ""
    
    init(videoID: String) {
        self.videoID = videoID
        _viewModel = StateObject(wrappedValue: CommentsViewModel(videoID: videoID))
    }
    
    var body: some View {
        VStack {
            List(viewModel.comments) { comment in
                VStack(alignment: .leading) {
                    Text(comment.uid)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(comment.text)
                }
            }
            HStack {
                TextField("Add a comment...", text: $commentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    viewModel.addComment(text: commentText)
                    commentText = ""
                }
            }
            .padding()
        }
        .navigationTitle("Comments")
    }
}
