import SwiftUI

struct VideoSidebarView: View {
    let numLikes: Int
    let numComments: Int
    let numBookmarks: Int
    let numShares: Int
    let isLiked: Bool
    let isBookmarked: Bool
    let onLike: () -> Void
    let onBookmark: () -> Void
    let onComment: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Like
            VStack(spacing: 4) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onLike()
                    }
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 30))
                        .foregroundColor(isLiked ? .red : .white)
                        .scaleEffect(isLiked ? 1.2 : 1.0)
                }
                Text("\(numLikes.abbreviated)")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            // Comment
            VStack(spacing: 4) {
                Button(action: {
                    onComment()
                }) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                Text("\(numComments.abbreviated)")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            // Bookmark
            VStack(spacing: 4) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onBookmark()
                    }
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .scaleEffect(isBookmarked ? 1.2 : 1.0)
                }
                Text("\(numBookmarks.abbreviated)")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            // Share
            VStack(spacing: 4) {
                Button {
                    print("[VideoSidebarView] Share tapped => count=\(numShares)")
                } label: {
                    Image(systemName: "arrowshape.turn.up.right")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                Text("\(numShares.abbreviated)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.bottom, 35)
            }
        }
        .onAppear {
            print("[VideoSidebarView] onAppear => Likes=\(numLikes), Comments=\(numComments).")
        }
    }
}
