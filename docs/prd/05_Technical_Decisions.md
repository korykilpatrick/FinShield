# FinShield – Opinionated Technical Decisions

This document summarizes key technical decisions for FinShield regarding video handling, AI integration, Firebase usage, and code organization.

## Video Handling and Performance
- **Use of AVKit/VideoPlayer**: Leverages native optimizations for video playback.
- **Preloading and Memory Management**: Preload upcoming videos and release off-screen players.
- **Video Resolution**: Limit uploads (e.g., 720p) to manage bandwidth and storage costs.

## AI Analysis Strategy
- **Off-device Processing**: Use Cloud Functions to run AI tasks, preserving mobile resources.
- **API Selection**: Utilize OpenAI’s Whisper for transcription and GPT-4 for misinformation detection.
- **Prompt Engineering**: Rely on carefully designed prompts to catch deceptive language.
- **Latency Considerations**: Accept asynchronous processing; results update via Firestore once available.

## Firebase Data Modeling and Performance
- **Denormalized Document Structure**: Consolidate video metadata in a single Firestore document for efficient retrieval.
- **Indexing and Querying**: Create indexes (e.g., on `timestamp`) to support smooth pagination.
- **Security Rules**: Enforce strict rules to prevent unauthorized manipulation of sensitive fields like analysis results.

## Code Structure and Maintainability
- **MVVM Architecture**: Use ViewModels to separate business logic from SwiftUI views.
- **Services Layer**: Implement dedicated classes for Firebase and AI API interactions.
- **Modular Components**: Break the UI into reusable components (e.g., `VideoCardView`, `MisinformationOverlayView`).

## Third-Party Libraries and Testing
- **Minimal Dependencies**: Favor native frameworks (SwiftUI, Firebase) over extra libraries.
- **Testing Strategy**: Write unit tests for API integrations and UI tests for critical features.
