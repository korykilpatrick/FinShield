import SwiftUI

struct VideoFeedView: View {
    @StateObject var viewModel = VideoFeedViewModel()
    @State private var currentIndex = 0
    
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                        VideoCellView(video: video)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .tag(index)  // Re-add tag for selection tracking
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentIndex) { newIndex in
                    // Preload next and previous videos
                    if newIndex > 0 {
                        viewModel.preloadVideo(at: newIndex - 1)
                    }
                    if newIndex < viewModel.videos.count - 1 {
                        viewModel.preloadVideo(at: newIndex + 1)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .statusBar(hidden: true)  // Hide status bar for true full screen
        .background(Color.black)
    }
}

struct VideoFeedView_Previews: PreviewProvider {
    static var previews: some View {
        VideoFeedView()
    }
}
