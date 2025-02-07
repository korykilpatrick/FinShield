import SwiftUI
import AVKit

// A tap recognizer that fails if the touch moves too far.
class NoSwipeTapGestureRecognizer: UITapGestureRecognizer {
    private var initialTouchPoint: CGPoint = .zero
    let movementThreshold: CGFloat = 10  // adjust as needed

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first, let view = self.view {
            initialTouchPoint = touch.location(in: view)
        }
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first, let view = self.view {
            let currentPoint = touch.location(in: view)
            let dx = abs(currentPoint.x - initialTouchPoint.x)
            let dy = abs(currentPoint.y - initialTouchPoint.y)
            if dx > movementThreshold || dy > movementThreshold {
                state = .failed
            }
        }
        super.touchesMoved(touches, with: event)
    }
}

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

struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    var onTap: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = LoggingAVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        
        let tap = NoSwipeTapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tap.cancelsTouchesInView = false
        controller.view.addGestureRecognizer(tap)
        
        // Log any found scroll view in the hierarchy (for debugging).
        DispatchQueue.main.async {
            var current: UIView? = controller.view
            while let view = current {
                if let scrollView = view as? UIScrollView {
                    print("[CustomVideoPlayer] Found UIScrollView in superview chain: \(scrollView)")
                    break
                }
                current = view.superview
            }
        }
        
        controller.view.isUserInteractionEnabled = true
        controller.contentOverlayView?.isUserInteractionEnabled = true
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
    
    class Coordinator: NSObject {
        let parent: CustomVideoPlayer
        
        init(_ parent: CustomVideoPlayer) {
            self.parent = parent
            print("[CustomVideoPlayer.Coordinator] init => done.")
        }
        
        @objc func handleTap() {
            print("[CustomVideoPlayer.Coordinator] handleTap => calling parent.onTap()")
            parent.onTap?()
        }
    }
}
