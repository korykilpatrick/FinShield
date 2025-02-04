import SwiftUI

struct VideoFeedView: View {
    @StateObject var viewModel = VideoFeedViewModel()
    
    var body: some View {
        GeometryReader { geo in
            if viewModel.videos.isEmpty {
                // Fallback UI when there are no videos.
                VStack {
                    Text("No videos available")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .background(Color.black)
            } else {
                // Use a rotated TabView to mimic TikTok-style vertical paging.
                TabView {
                    ForEach(viewModel.videos) { video in
                        VideoCellView(video: video)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            // Rotate the video view 90° so that the TabView can be rotated back.
                            .rotationEffect(.degrees(90))
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                // Rotate the TabView to allow vertical swiping.
                .rotationEffect(.degrees(-90))
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .ignoresSafeArea() // Use full screen.
    }
}

struct VideoFeedView_Previews: PreviewProvider {
    static var previews: some View {
        VideoFeedView()
    }
}
