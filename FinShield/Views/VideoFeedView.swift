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
                let pages: [UIHostingController<AnyView>] = viewModel.videos.enumerated().map { (index, video) in
                    let player = viewModel.getPreloadedPlayer(for: index)
                    let cellVM = VideoCellViewModel(video: video)
                    let cell = VideoCellView(
                        viewModel: cellVM,
                        preloadedPlayer: player,
                        index: index,
                        activePage: $currentIndex
                    )
                    return UIHostingController(rootView: AnyView(cell))
                }
                
                CustomPageView(pages: pages, currentPage: $currentIndex)
                    .ignoresSafeArea()
            }
        }
    }
}
