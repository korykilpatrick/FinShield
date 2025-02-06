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
                // Build an array of pages (each page is a VideoCellView)
                let pages: [UIHostingController<AnyView>] = viewModel.videos.enumerated().map { (index, video) in
                    let player = viewModel.getPreloadedPlayer(for: index)
                    let cell = VideoCellView(video: video,
                                             preloadedPlayer: player,
                                             index: index,
                                             activePage: $currentIndex)
                    return UIHostingController(rootView: AnyView(cell))
                }
                
                CustomPageView(pages: pages, currentPage: $currentIndex)
                    .ignoresSafeArea()
            }
        }
    }
}
