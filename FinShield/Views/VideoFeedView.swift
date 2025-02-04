import SwiftUI

// VideoFeedView
struct VideoFeedView: View {
    @StateObject var viewModel = VideoFeedViewModel()
    @State private var currentIndex = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if viewModel.videos.isEmpty {
                Text("No videos available")
                    .foregroundColor(.white)
            } else {
                let multiplier = 1000
                let totalCount = viewModel.videos.count * multiplier
                TabView(selection: $currentIndex) {
                    ForEach(0..<totalCount, id: \.self) { index in
                        VideoCellView(video: viewModel.videos[index % viewModel.videos.count])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
                // For iOS 16+, use .vertical() on PageTabViewStyle:
                // .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never).vertical())
                .onAppear { currentIndex = totalCount / 2 }
                .onChange(of: currentIndex) { newIndex in
                    let mod = newIndex % viewModel.videos.count
                    let prev = (mod - 1 + viewModel.videos.count) % viewModel.videos.count
                    let next = (mod + 1) % viewModel.videos.count
                    viewModel.preloadVideo(at: prev)
                    viewModel.preloadVideo(at: next)
                }
            }
        }
    }
}


struct VideoFeedView_Previews: PreviewProvider {
    static var previews: some View {
        VideoFeedView()
    }
}
