import SwiftUI

struct VideoFeedView: View {
    @StateObject var viewModel = VideoFeedViewModel()
    @State private var currentIndex = 0
    
    // Reduced multiplier to limit total TabView pages
    private let multiplier = 50
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.videos.isEmpty {
                Text("No videos available")
                    .foregroundColor(.white)
            } else {
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
                    // Center the feed
                    currentIndex = totalCount / 2
                    print("[\(Date())] onAppear => currentIndex = \(currentIndex)")
                }
                .onChange(of: currentIndex) { newIndex in
                    let mod = newIndex % viewModel.videos.count
                    print("[\(Date())] currentIndex changed => \(newIndex) [mod: \(mod)]")
                    
                    // Preload current, +/-2
                    (mod-2...mod+2).forEach { viewModel.preloadVideo(at: $0) }
                }
            }
        }
        .onChange(of: viewModel.videos) { newVideos in
            // Whenever videos reload, reset currentIndex to the middle
            if !newVideos.isEmpty {
                let totalCount = newVideos.count * multiplier
                currentIndex = totalCount / 2
            }
        }
    }
}

struct VideoFeedView_Previews: PreviewProvider {
    static var previews: some View {
        VideoFeedView()
    }
}
