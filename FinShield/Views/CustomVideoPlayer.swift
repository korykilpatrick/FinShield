import SwiftUI
import AVKit

struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeCoordinator() -> Coordinator {
        print("[CustomVideoPlayer] makeCoordinator called.")
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        print("[CustomVideoPlayer] makeUIViewController called.")
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        
        // Disable UIKit touch handling so taps pass through to SwiftUI
        controller.view.isUserInteractionEnabled = false
        controller.contentOverlayView?.isUserInteractionEnabled = false
        
        if let overlay = controller.contentOverlayView {
            print("[CustomVideoPlayer] contentOverlayView exists.")
        } else {
            print("[CustomVideoPlayer] contentOverlayView is nil; will use controller.view.")
        }
        
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        print("[CustomVideoPlayer] updateUIViewController called.")
        uiViewController.player = player
    }

    class Coordinator: NSObject {
        let parent: CustomVideoPlayer

        init(_ parent: CustomVideoPlayer) {
            self.parent = parent
            super.init()
            print("[CustomVideoPlayer.Coordinator] Initialized.")
        }
    }
}
