# Interaction Layering and Responsibility Separation for User Interactions in FinShield

## Overview
This document outlines the approach used in the FinShield project for managing user interactions on video pages. Our goal is to deliver a smooth, TikTok/YouTube–like experience where:

- **Swipes** are used for page transitions.
- **Taps** in the main video area toggle playback.
- **Interactive overlays** (e.g., sidebars, metadata, popups) capture their own touch events without interference from the base video layer.

## Architectural Layers

### 1. UIPageViewController Layer (Paging)
- **Responsibility:** Manages a collection of video pages.
- **Mechanism:**  
  - Uses an internal `UIScrollView` to detect horizontal swipes for page navigation.
  - Its gesture recognizers are solely responsible for handling swipes.

### 2. Video Layer (Playback)
- **Responsibility:** Displays the video content.
- **Mechanism:**  
  - Uses an `AVPlayerViewController` wrapped in a custom view (`CustomVideoPlayer`) to render video.
  - A tap gesture recognizer is attached to the video layer to toggle play/pause.
  - This layer occupies the full screen behind the interactive overlays.

### 3. Interactive Overlay Layer
- **Responsibility:** Provides user interaction for video metadata, sidebar actions (like, comment, bookmark, share), and future popups.
- **Mechanism:**  
  - Overlays (such as the bottom metadata view and sidebar) are added on top of the video layer.
  - These overlays have their own hit-testing enabled, so when a user taps within their bounds, the overlay’s gesture handlers (buttons, tap gestures) capture the event.
  - Taps outside these overlays fall through to the video layer.

## Interaction Flow

1. **Swiping:**
   - A swipe gesture on the screen is captured by the `UIScrollView` (inside the `UIPageViewController`), triggering a page transition.

2. **Tapping in Non-Overlay Areas:**
   - Taps that occur outside the defined overlay boundaries are handled by the video layer’s tap recognizer, toggling play or pause.

3. **Tapping on Overlays:**
   - Taps within the overlay boundaries (e.g., on the sidebar or metadata area) are captured by the overlay’s own interactive elements.
   - This ensures that interactions such as liking, commenting, or triggering popups are handled correctly and do not trigger the video’s play/pause behavior.

## Advantages of This Approach
- **Clear Separation of Responsibilities:**  
  Each layer is responsible for its own set of interactions:
  - **Paging Layer:** Handles swipes.
  - **Video Layer:** Handles basic tap actions.
  - **Overlay Layer:** Handles specific interactive elements.
  
- **Scalability and Extendability:**  
  Adding new interactive elements (like popups or additional buttons) is as simple as creating new overlays with their own gesture handlers.

- **Reduced Gesture Conflicts:**  
  By using natural hit-testing and defined layers, we avoid the complexity of forcing one gesture recognizer to wait for another (which can be fragile when using system components like `AVPlayerViewController`).

## Considerations and Alternatives
- **Custom Gesture Recognizers:**  
  While it’s possible to build a custom gesture recognizer that distinguishes between small taps and larger swipes by measuring displacement, this approach becomes complex when combined with system-provided recognizers (e.g., those in `UIPageViewController` and `AVPlayerViewController`).

- **Interaction Boundaries:**  
  Carefully defining the size and location of interactive overlays is crucial. Overly large overlays may capture unintended touches, while overly small ones may lead to missed interactions.

- **Future Enhancements:**  
  As the project evolves (e.g., adding popups or more detailed metadata interactions), new overlays can be added or existing ones modified without overhauling the base interaction model.

## Conclusion
Our current design leverages layered responsibilities to cleanly separate user interactions:

- **Paging** is managed by the UIPageViewController’s internal scroll view.
- **Video playback controls** (e.g., play/pause) are handled by a simple tap recognizer on the video layer.
- **Interactive overlays** capture their own gestures, ensuring that popups, sidebars, and metadata interactions are processed independently.

This approach not only minimizes gesture conflicts but also provides a solid foundation for future extensions, making the system both maintainable and scalable.

---

*Reference this document when making changes to user interaction logic or when extending the UI with additional interactive elements.*