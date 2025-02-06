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
            // Like button
            VStack(spacing: 4) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { onLike() }
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 30))
                        .foregroundColor(isLiked ? .red : .white)
                        .scaleEffect(isLiked ? 1.2 : 1.0)
                }
                Text("\(numLikes)")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            // Comments button
            VStack(spacing: 4) {
                Button(action: { onComment() }) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                Text("\(numComments)")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            // Bookmark button
            VStack(spacing: 4) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { onBookmark() }
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .scaleEffect(isBookmarked ? 1.2 : 1.0)
                }
                Text("\(numBookmarks)")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            // Share button
            VStack(spacing: 4) {
                Button {
                    // Share action
                } label: {
                    Image(systemName: "arrowshape.turn.up.right")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                Text("\(numShares)")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
}

struct VideoSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VideoSidebarView(
                numLikes: 123,
                numComments: 45,
                numBookmarks: 67,
                numShares: 8,
                isLiked: false,
                isBookmarked: false,
                onLike: {},
                onBookmark: {},
                onComment: {}
            )
            .padding(.trailing, 10)
        }
    }
}
