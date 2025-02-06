import SwiftUI
import UIKit

/// A generic wrapper around UIPageViewController that hosts an array of SwiftUI views.
struct CustomPageView<Page: View>: UIViewControllerRepresentable {
    var pages: [UIHostingController<Page>]
    @Binding var currentPage: Int

    func makeCoordinator() -> Coordinator {
        print("[CustomPageView] makeCoordinator => creating coordinator.")
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        print("[CustomPageView] makeUIViewController => building UIPageViewController.")
        let pageVC = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        pageVC.dataSource = context.coordinator
        pageVC.delegate = context.coordinator

        // Locate the internal scroll view and tweak its properties to allow both swiping and tap detection.
        if let scrollView = pageVC.view.subviews.compactMap({ $0 as? UIScrollView }).first {
            print("[CustomPageView] Found UIScrollView => canCancelContentTouches = \(scrollView.canCancelContentTouches), delaysContentTouches = \(scrollView.delaysContentTouches)")
            scrollView.delaysContentTouches = false
            scrollView.canCancelContentTouches = false

            for recognizer in scrollView.gestureRecognizers ?? [] {
                let className = NSStringFromClass(type(of: recognizer))
                // For built-in pan and delayed touches, keep the delegate intact.
                if className.contains("PanGestureRecognizer") || className.contains("DelayedTouches") {
                    print("[CustomPageView] Skipping setting delegate for built-in recognizer: \(className)")
                } else {
                    recognizer.delegate = context.coordinator
                    print("[CustomPageView] Setting recognizer delegate for \(className)")
                }
            }
        }

        pageVC.setViewControllers(
            [pages[currentPage]],
            direction: .forward,
            animated: false
        )

        return pageVC
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        print("[CustomPageView] updateUIViewController => setting currentPage = \(currentPage).")
        uiViewController.setViewControllers(
            [pages[currentPage]],
            direction: .forward,
            animated: true
        )
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIGestureRecognizerDelegate {
        var parent: CustomPageView

        init(_ parent: CustomPageView) {
            print("[CustomPageView.Coordinator] init => done.")
            self.parent = parent
            super.init()
        }

        // MARK: - UIPageViewControllerDataSource
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let index = parent.pages.firstIndex(of: viewController as! UIHostingController<Page>) else {
                print("[CustomPageView.Coordinator] viewControllerBefore => index not found.")
                return nil
            }
            let prevIndex = index - 1
            print("[CustomPageView.Coordinator] viewControllerBefore => index=\(index), prevIndex=\(prevIndex).")
            return prevIndex >= 0 ? parent.pages[prevIndex] : nil
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let index = parent.pages.firstIndex(of: viewController as! UIHostingController<Page>) else {
                print("[CustomPageView.Coordinator] viewControllerAfter => index not found.")
                return nil
            }
            let nextIndex = index + 1
            print("[CustomPageView.Coordinator] viewControllerAfter => index=\(index), nextIndex=\(nextIndex).")
            return nextIndex < parent.pages.count ? parent.pages[nextIndex] : nil
        }

        // MARK: - UIPageViewControllerDelegate
        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            print("[CustomPageView.Coordinator] didFinishAnimating => finished=\(finished), completed=\(completed).")
            if completed,
               let currentVC = pageViewController.viewControllers?.first as? UIHostingController<Page>,
               let index = parent.pages.firstIndex(of: currentVC) {
                parent.currentPage = index
                print("[CustomPageView.Coordinator] didFinishAnimating => updated currentPage=\(index).")
            }
        }

        // MARK: - UIGestureRecognizerDelegate
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            print("[CustomPageView.Coordinator] gestureRecognizerShouldBegin => \(gestureRecognizer).")
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            print("[CustomPageView.Coordinator] shouldRecognizeSimultaneouslyWith => \(gestureRecognizer) & \(otherGestureRecognizer).")
            return true
        }
    }
}
