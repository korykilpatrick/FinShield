import SwiftUI
import AVKit

class LoggingAVPlayerViewController: AVPlayerViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let overlay = contentOverlayView {
            print("[LoggingAVPlayerViewController] contentOverlayView frame: \(overlay.frame)")
        }
    }
    
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
        controller.videoGravity = .resizeAspect

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.delegate = context.coordinator
        tap.cancelsTouchesInView = false

        // Check if contentOverlayView has a nonzero frame.
        if let overlay = controller.contentOverlayView, overlay.bounds.size != .zero {
            overlay.addGestureRecognizer(tap)
            overlay.isUserInteractionEnabled = true
            print("[CustomVideoPlayer] Attached tap recognizer to contentOverlayView: \(overlay)")
        } else {
            // Fall back to attaching to controller.view.
            controller.view.addGestureRecognizer(tap)
            print("[CustomVideoPlayer] contentOverlayView is zero sized; attached tap recognizer to controller.view")
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let parent: CustomVideoPlayer

        init(_ parent: CustomVideoPlayer) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            print("[CustomVideoPlayer.Coordinator] handleTap called with state \(gesture.state.rawValue) at location \(location)")
            if gesture.state == .ended {
                print("[CustomVideoPlayer.Coordinator] Gesture ended – calling onTap")
                parent.onTap?()
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            print("[CustomVideoPlayer.Coordinator] shouldRecognizeSimultaneouslyWith called with other: \(otherGestureRecognizer)")
            return true
        }
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            print("[CustomVideoPlayer.Coordinator] gestureRecognizerShouldBegin called for \(gestureRecognizer)")
            return true
        }
    }
}
