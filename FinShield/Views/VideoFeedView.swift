import SwiftUI

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
                        let modIndex = index % viewModel.videos.count
                        VideoCellView(
                            video: viewModel.videos[modIndex],
                            preloadedPlayer: viewModel.getPreloadedPlayer(for: modIndex)
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
                .onAppear {
                    currentIndex = totalCount / 2
                }
                .onChange(of: currentIndex) { newIndex in
                    let mod = newIndex % viewModel.videos.count
                    // Preload five videos: current, two before, and two after.
                    viewModel.preloadVideo(at: mod - 2)
                    viewModel.preloadVideo(at: mod - 1)
                    viewModel.preloadVideo(at: mod)
                    viewModel.preloadVideo(at: mod + 1)
                    viewModel.preloadVideo(at: mod + 2)
                }
            }
        }
    }
}
