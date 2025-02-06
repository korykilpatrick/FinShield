import SwiftUI
import AVKit

class LoggingAVPlayerViewController: AVPlayerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[LoggingAVPlayerViewController] viewDidLoad => player:", player as Any)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("[LoggingAVPlayerViewController] viewWillAppear => animated:", animated)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("[LoggingAVPlayerViewController] viewDidAppear => animated:", animated)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        print("[LoggingAVPlayerViewController] touchesBegan => forwarding to next responder.")
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        print("[LoggingAVPlayerViewController] touchesEnded => forwarding to next responder.")
    }
}

/// Wraps an AVPlayer with a dedicated UITapGestureRecognizer that calls `onTap`.
struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    var onTap: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        print("[CustomVideoPlayer] makeCoordinator => creating Coordinator.")
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        print("[CustomVideoPlayer] makeUIViewController => building LoggingAVPlayerViewController.")
        let controller = LoggingAVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill

        // Attach a UITapGestureRecognizer directly to the controller’s view.
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tap.cancelsTouchesInView = false
        controller.view.addGestureRecognizer(tap)

        controller.view.isUserInteractionEnabled = true
        controller.contentOverlayView?.isUserInteractionEnabled = true

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        print("[CustomVideoPlayer] updateUIViewController => updating player ref.")
        uiViewController.player = player
    }

    class Coordinator: NSObject {
        let parent: CustomVideoPlayer

        init(_ parent: CustomVideoPlayer) {
            self.parent = parent
            super.init()
            print("[CustomVideoPlayer.Coordinator] init => done.")
        }
        
        @objc func handleTap() {
            print("[CustomVideoPlayer.Coordinator] handleTap => calling parent.onTap()")
            parent.onTap?()
        }
    }
}
