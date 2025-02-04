import SwiftUI
import FirebaseAuth

struct CommentsView: View {
    let videoID: String
    @StateObject var viewModel: CommentsViewModel
    @State private var commentText: String = ""
    @Environment(\.dismiss) private var dismiss
    
    init(videoID: String) {
        self.videoID = videoID
        _viewModel = StateObject(wrappedValue: CommentsViewModel(videoID: videoID))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Comments")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            // Comments List
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.comments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No comments yet")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.comments) { comment in
                        CommentCell(comment: comment, canDelete: comment.uid == Auth.auth().currentUser?.uid)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if comment.uid == Auth.auth().currentUser?.uid {
                                    Button(role: .destructive) {
                                        viewModel.deleteComment(comment)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            // Comment Input
            VStack(spacing: 0) {
                Divider()
                HStack {
                    TextField("Add a comment...", text: $commentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.isLoading)
                    
                    Button(action: {
                        viewModel.addComment(text: commentText)
                        commentText = ""
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(commentText.isEmpty ? .gray : .blue)
                    }
                    .disabled(commentText.isEmpty || viewModel.isLoading)
                }
                .padding()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }
}

struct CommentCell: View {
    let comment: Comment
    let canDelete: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(comment.username)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(comment.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(comment.text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CommentsView(videoID: "preview")
}
