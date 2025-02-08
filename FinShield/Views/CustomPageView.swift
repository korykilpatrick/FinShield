import SwiftUI
import UIKit

struct CustomPageView: UIViewControllerRepresentable {
    let pages: [UIHostingController<AnyView>]
    @Binding var currentPage: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageVC = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        pageVC.dataSource = context.coordinator
        pageVC.delegate = context.coordinator
        pageVC.setViewControllers([pages[currentPage]], direction: .forward, animated: false)
        return pageVC
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        // Update only if the visible view controller isn’t already the current page.
        if let currentVC = uiViewController.viewControllers?.first,
           let index = pages.firstIndex(of: currentVC as! UIHostingController<AnyView>),
           index != currentPage {
            let direction: UIPageViewController.NavigationDirection = (currentPage > index) ? .forward : .reverse
            uiViewController.setViewControllers([pages[currentPage]], direction: direction, animated: true)
        }
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: CustomPageView

        init(_ parent: CustomPageView) {
            self.parent = parent
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = parent.pages.firstIndex(of: viewController as! UIHostingController<AnyView>) else { return nil }
            let prevIndex = index - 1
            return prevIndex < 0 ? parent.pages.last : parent.pages[prevIndex]
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = parent.pages.firstIndex(of: viewController as! UIHostingController<AnyView>) else { return nil }
            let nextIndex = index + 1
            return nextIndex >= parent.pages.count ? parent.pages.first : parent.pages[nextIndex]
        }
        
        func pageViewController(_ pageViewController: UIPageViewController,
                                didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController],
                                transitionCompleted completed: Bool) {
            if completed, let visibleVC = pageViewController.viewControllers?.first,
               let index = parent.pages.firstIndex(of: visibleVC as! UIHostingController<AnyView>) {
                parent.currentPage = index
            }
        }
    }
}
