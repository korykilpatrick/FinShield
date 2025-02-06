import SwiftUI
import UIKit

/// A generic wrapper around UIPageViewController that hosts an array of SwiftUI views.
struct CustomPageView<Page: View>: UIViewControllerRepresentable {
    var pages: [UIHostingController<Page>]
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
        uiViewController.setViewControllers([pages[currentPage]], direction: .forward, animated: true)
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: CustomPageView
        
        init(_ parent: CustomPageView) {
            self.parent = parent
        }
        
        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = parent.pages.firstIndex(of: viewController as! UIHostingController<Page>) else {
                return nil
            }
            let prevIndex = index - 1
            return prevIndex >= 0 ? parent.pages[prevIndex] : nil
        }
        
        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = parent.pages.firstIndex(of: viewController as! UIHostingController<Page>) else {
                return nil
            }
            let nextIndex = index + 1
            return nextIndex < parent.pages.count ? parent.pages[nextIndex] : nil
        }
        
        func pageViewController(_ pageViewController: UIPageViewController,
                                didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController],
                                transitionCompleted completed: Bool) {
            if completed, let currentVC = pageViewController.viewControllers?.first as? UIHostingController<Page>,
               let index = parent.pages.firstIndex(of: currentVC) {
                parent.currentPage = index
            }
        }
    }
}
