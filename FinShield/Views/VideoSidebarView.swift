//
//  VideoSidebarView.swift
//  FinShield
//
//  Created by Kory Kilpatrick on 2/5/25.
//


import SwiftUI

struct VideoSidebarView: View {
    let numLikes: Int
    let numComments: Int
    let numBookmarks: Int
    let numShares: Int

    var body: some View {
        VStack(spacing: 20) {
            // Heart (Likes)
            VStack(spacing: 4) {
                Button {
                    // Toggle like action
                } label: {
                    Image(systemName: "heart")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                Text("\(numLikes)")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            // Comments
            VStack(spacing: 4) {
                Button {
                    // Show comments action
                } label: {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                Text("\(numComments)")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            // Bookmark
            VStack(spacing: 4) {
                Button {
                    // Bookmark action
                } label: {
                    Image(systemName: "bookmark")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                Text("\(numBookmarks)")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            // Share
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
            VideoSidebarView(numLikes: 1234, numComments: 56, numBookmarks: 78, numShares: 9)
                .padding(.trailing, 10)
        }
    }
}
