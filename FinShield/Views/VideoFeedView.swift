import SwiftUI


struct VideoFeedView: View {
    @StateObject var viewModel = VideoFeedViewModel()
    
    var body: some View {
        VStack {
            if viewModel.videos.isEmpty {
                Text("Click here to watch Jordan MeatSpin!!!")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
            } else {
                // Your existing TabView code…
            }
        }
    }
}

// struct VideoFeedView: View {
//     @StateObject var viewModel = VideoFeedViewModel()
    
//     var body: some View {
//         GeometryReader { geo in
//             TabView {
//                 ForEach(viewModel.videos) { video in
//                     VideoCellView(video: video)
//                         .frame(width: geo.size.width, height: geo.size.height)
//                         .clipped()
//                         .rotationEffect(.degrees(90))
//                         .frame(width: geo.size.width, height: geo.size.height)
//                 }
//             }
//             .frame(width: geo.size.width, height: geo.size.height)
//             .rotationEffect(.degrees(-90))
//             .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
//         }
//     }
// }
