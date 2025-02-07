import SwiftUI
import AVKit

class LoggingAVPlayerViewController: AVPlayerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[LoggingAVPlayerViewController] viewDidLoad with player: \(String(describing: player))")
    }
}

struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    var onTap: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = LoggingAVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill

        // Attach a simple tap recognizer to the content overlay.
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tap.cancelsTouchesInView = false
        if let overlay = controller.contentOverlayView {
            overlay.addGestureRecognizer(tap)
            overlay.isUserInteractionEnabled = true
        } else {
            // Fallback: attach to the main view.
            controller.view.addGestureRecognizer(tap)
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }

    class Coordinator: NSObject {
        let parent: CustomVideoPlayer

        init(_ parent: CustomVideoPlayer) {
            self.parent = parent
        }

        @objc func handleTap() {
            print("[CustomVideoPlayer.Coordinator] handleTap called")
            parent.onTap?()
        }
    }
}
