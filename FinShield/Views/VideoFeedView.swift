import SwiftUI

struct VideoFeedView: View {
    @StateObject var viewModel = VideoFeedViewModel()
    @State private var currentIndex = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { geo in
                if viewModel.videos.isEmpty {
                    VStack {
                        Text("No videos available")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    let multiplier = 1000
                    let totalCount = viewModel.videos.count * multiplier

                    TabView(selection: $currentIndex) {
                        ForEach(0..<totalCount, id: \.self) { index in
                            VideoCellView(video: viewModel.videos[index % viewModel.videos.count])
                                // Swap width/height since the TabView is rotated.
                                .frame(width: geo.size.height, height: geo.size.width)
                                .rotationEffect(.degrees(-90))
                                .tag(index)
                        }
                    }
                    // Keep TabView full screen before rotation.
                    .frame(width: geo.size.width, height: geo.size.height)
                    .rotationEffect(.degrees(90))
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .onChange(of: currentIndex) { newIndex in
                        let mod = newIndex % viewModel.videos.count
                        let prev = (mod - 1 + viewModel.videos.count) % viewModel.videos.count
                        let next = (mod + 1) % viewModel.videos.count
                        viewModel.preloadVideo(at: prev)
                        viewModel.preloadVideo(at: next)
                    }
                    .onAppear {
                        if currentIndex == 0 { currentIndex = totalCount / 2 }
                    }
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
