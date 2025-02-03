
**File: 04_Milestones.md**

```markdown
# FinShield – Checkpoints & Milestones (MVP Development Plan)

This document outlines key milestones for building and validating the FinShield MVP.

## Milestone 0: Environment Setup Complete
- **Outcome**: Xcode, SwiftUI, and Firebase are configured.
- **Checkpoint**: “Hello, FinShield!” displays on the simulator.

## Milestone 1: Basic UI Scaffold & Video Playback
- Implement a video feed with placeholder content.
- Integrate full-screen `VideoPlayer` and swipe navigation.
- Add dummy overlay UI elements.
- **Checkpoint**: Users can swipe between videos with visible overlays.

## Milestone 2: Firebase Integration (Data & Auth)
- Replace static content with dynamic Firestore data.
- Integrate Firebase Authentication (if required).
- **Checkpoint**: The video feed updates in real time from Firestore.

## Milestone 3: Video Upload Functionality
- Develop a video upload interface (using `PhotosPicker`).
- Upload videos to Firebase Storage and create a Firestore document.
- **Checkpoint**: New uploads appear in the video feed.

## Milestone 4: AI Pipeline Integration (Backend)
- Build Cloud Functions for speech-to-text and content analysis.
- Test API calls to OpenAI (or Anthropic) for transcription and analysis.
- **Checkpoint**: Uploaded videos are processed; Firestore documents update with transcript and flag data.

## Milestone 5: Frontend Misinformation Overlay
- Update the UI to show misinformation indicators based on Firestore analysis results.
- Implement an interactive popup with flag reasons and educational links.
- **Checkpoint**: Flagged videos display the overlay, allowing user interaction for more info.

## Milestone 6: Refinement and UX Improvements
- Optimize video playback (preloading, caching, pausing off-screen).
- Enhance error handling and tighten Firebase security rules.
- **Checkpoint**: The MVP is polished, smooth, and ready for demonstration.
