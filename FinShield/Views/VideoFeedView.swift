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
                    .onAppear {
                        print("[VideoFeedView] No videos => .isEmpty.")
                    }
            } else {
                // Each page is a VideoCellView, hosted in a UIHostingController
                let pages: [UIHostingController<AnyView>] = viewModel.videos.enumerated().map { (index, video) in
                    let player = viewModel.getPreloadedPlayer(for: index)
                    let cell = VideoCellView(
                        video: video,
                        preloadedPlayer: player,
                        index: index,
                        activePage: $currentIndex
                    )
                    return UIHostingController(rootView: AnyView(cell))
                }
                
                CustomPageView(pages: pages, currentPage: $currentIndex)
                    .ignoresSafeArea()
                    .onAppear {
                        print("[VideoFeedView] Showing page view => #videos = \(viewModel.videos.count)")
                    }
            }
        }
    }
}
