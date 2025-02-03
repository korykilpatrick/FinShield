**File: 03_Technical_Architecture.md**

```markdown
# FinShield – Technical Architecture

This document details the architecture for FinShield, comprising three main components: the Frontend (SwiftUI), the Backend (Firebase), and the AI Pipeline (speech-to-text and content analysis).

## 1. Frontend (SwiftUI App)

### Main Feed UI
- **Video Feed**: Implement a vertically scrollable feed (using `ScrollView` or `TabView` with paging) that mimics TikTok.
- **Video Player**: Use SwiftUI’s `VideoPlayer` (from AVKit) for full-screen video playback:
  ```swift
  import AVKit
  VideoPlayer(player: AVPlayer(url: videoURL))
- Swipe Navigation: Integrate swipe gestures or SwiftUI paging to navigate between videos.

Overlay UI Elements
- Misinformation Indicator: Display a small icon (e.g., a red “⚠️”) on videos flagged by AI.
- Educational Context Popup: On tapping the indicator, present a sheet with detailed explanations (flag reasons and an educational link).

Video Upload Interface
- Allow users to upload videos via SwiftUI’s PhotosPicker or a UIKit-based UIImagePickerController.
- Upload video files to Firebase Storage and create corresponding Firestore documents.

Authentication
Integrate Firebase Authentication (e.g., Sign-in with Apple, Email/Password, or Anonymous login) to secure uploads and user data.
2. Backend (Firebase)
Firestore Data Model
videos Collection: Each document should contain:
videoURL
thumbnailURL
uploaderID
description
transcript
isFlagged
flagReasons
contextLink
timestamp
users Collection: User profiles and settings.
(Optional) resources Collection: A curated set of educational links keyed by topic.
Firebase Storage
Store video files at a path like videos/{userId}/{videoId}.mp4.
Utilize CDN-backed URLs for efficient streaming.
Cloud Functions (Node.js)
Trigger: Functions trigger on new video uploads (Firestore onCreate or Storage finalization).
Speech-to-Text: Call OpenAI’s Whisper API to transcribe audio.
Content Analysis: Send the transcript to GPT-4/GPT-3.5 for evaluating potential misinformation.
Result Update: Write the analysis (transcript, flag status, reasons, context link) back to the Firestore document.
3. AI Pipeline
Speech-to-Text:
Extract the audio track from the video.
Send the audio to an AI API (e.g., OpenAI Whisper) for transcription.
Content Analysis:
Submit the transcript to an LLM (OpenAI GPT-4 or GPT-3.5) using a prompt to detect misleading claims.
Parse the LLM’s structured output (e.g., JSON) to obtain:
isFlagged (boolean)
flagReasons (array or string)
contextLink (URL)
Realtime Updates:
Utilize Firestore real-time listeners to update the UI when the Cloud Function finishes processing.