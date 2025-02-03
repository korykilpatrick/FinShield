# FinShield – Technical Product Requirements Document (PRD)

## Overview

FinShield is a mobile iOS application (iPhone) that presents short-form videos in a TikTok-like feed and uses AI to detect potential financial misinformation in those videos. Users can upload videos with financial advice or claims, and FinShield's backend will transcribe the audio and analyze the content for misleading or scam-like information. The app will overlay warnings or educational context on videos flagged by the AI, providing users with links to learn more. This PRD outlines the development plan, technical architecture, milestones, and key decisions for building FinShield using SwiftUI (frontend) and Firebase (backend), with AI services (OpenAI/Anthropic) for speech-to-text and content analysis.

## 1. Development Environment Setup

To build FinShield, developers will use a Mac (Apple Silicon M-series, e.g. "M4") and set up the iOS development environment with SwiftUI and Firebase integration. Below are the step-by-step setup instructions and an initial "Hello, World" milestone to verify the environment:

### 1.1 Required Tools and Installation

1. Install Xcode: Download and install the latest Xcode from the Mac App Store or Apple Developer website. Ensure Xcode is updated (e.g. Xcode 15+ for iOS 17 compatibility) and that Command Line Tools are installed (Xcode > Preferences > Locations > Command Line Tools). This provides Swift, SwiftUI, and iOS simulators.

2. SwiftUI Project Setup: Open Xcode and create a new iOS App project. Choose the App template with SwiftUI interface and Swift language. Name the project "FinShield". Select your Team or "None" for code signing (you can use an Apple ID for a free development provisioning profile if needed).

3. Install CocoaPods or Swift Package Manager (SPM): FinShield will use Firebase, which can be added via SPM (preferred) or CocoaPods. For SPM, in Xcode go to File > Add Packages... and add the Firebase Swift SDK packages. If using CocoaPods instead, ensure Homebrew is installed (/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"), then install CocoaPods (brew install cocoapods) and run pod init in the project directory.

4. Add Firebase SDKs:
   - Create a Firebase project on the Firebase Console named "FinShield". Register an iOS app with the project (using the app's bundle ID). Download the GoogleService-Info.plist config file and add it to the Xcode project (ensure it's included in the app target).
   - Using SPM: Add the Firebase Apple SDK repository (e.g. https://github.com/firebase/firebase-ios-sdk) and select the necessary SDKs: Firebase/Auth, Firebase/Firestore, Firebase/Storage (and Firebase/Analytics if desired for logging).
   - If using CocoaPods: in the Podfile, include pods for Firebase Analytics, Firestore, Auth, and Storage. Run pod install and open the generated .xcworkspace.

5. Initialize Firebase in App: In the SwiftUI app, initialize Firebase during app launch. In SwiftUI lifecycle, you can create an AppDelegate (using UIApplicationDelegateAdaptor) or call FirebaseApp.configure() inside the init() of the main App struct. This ensures Firebase is ready for use (authentication, database calls, etc.).

Hello, World Milestone: As a quick test of the environment, modify the default SwiftUI ContentView to display a greeting and run the app:
- In ContentView.swift, set the body to Text("Hello, FinShield!") with some styling.
- Build and run the app on an iOS Simulator (e.g. iPhone 15). You should see the "Hello, FinShield!" message on screen. This confirms that SwiftUI is working and the app launches successfully.
- (Optional) Verify Firebase setup by adding a simple test call, such as writing a test document to Firestore or printing a log in AppDelegate after FirebaseApp.configure(). Not strictly necessary at this stage, but it can confirm Firebase is configured correctly.

By completing these steps, the development environment will be ready. The "Hello, World" milestone verifies that Xcode, SwiftUI, and Firebase basics are set up correctly before proceeding to build the actual features.

## 2. Technical Architecture

FinShield's architecture is divided into three primary components: the frontend iOS app (built with SwiftUI for the UI/UX), the backend on Firebase (which handles data storage, authentication, and serves as a trigger point for AI processing), and the AI analysis pipeline (leveraging external AI services for speech transcription and misinformation detection). Below is an overview of each part of the system and how they interact:

### 2.1 Frontend (SwiftUI App) Structure

The iOS application UI will mimic the TikTok vertical video feed experience, using SwiftUI views. Key elements of the frontend architecture include:

Main Feed UI: The core of the app is a vertically scrollable feed of videos. This can be implemented using a TabView or ScrollView with paging, or a custom container that allows swipe-up/down to transition between full-screen videos. Each video is presented in a full-screen SwiftUI View that contains a video player and overlays.

Video Player: Use SwiftUI's VideoPlayer (from AVKit) to play video content. This provides a native video player that can play a video from a URL or asset with minimal code. For example, VideoPlayer(player: AVPlayer(url: ...)) will embed an AVPlayer. We will configure the player for looped playback so that short videos replay automatically (using AVPlayerLooper or by monitoring playback end and seeking to start)​. The video player view should fill the screen and support sound (respecting the silent switch and volume controls).

Swipe Navigation: When the user swipes up, the next video in the feed should load and play. Swiping down goes to the previous video. We can achieve this by storing an array of video items (with their URLs and metadata) and the current index, and using SwiftUI's paging capabilities (e.g. a TabView with tabViewStyle(PageTabViewStyle()) configured for vertical paging in iOS 17+) or a third-party solution if needed to reproduce TikTok's smooth swipe behavior. The app should preload the next video (or a few) for seamless transitions, using lazy loading to avoid memory overload.

Overlay UI Elements: Similar to TikTok, each video will have UI overlays on top of the video content. In FinShield, overlays serve two purposes: conventional video actions (like, share, etc.) and misinformation indicators. We will use a SwiftUI ZStack to layer the overlay elements on top of the VideoPlayer. For example, TikTok's UI has like/comment/share buttons on the right and a caption at the bottom; we can place comparable SwiftUI VStack or HStack views in a ZStack alignment.

Misinformation Indicator: FinShield's unique overlay is an indicator when a video's content is flagged by the AI. This might be a small semi-transparent banner or an icon badge that appears on the video. For instance, a red "⚠️" icon or an info "ℹ️" icon could appear at a corner of the video if the AI detects possible misinformation. Tapping this indicator could open a detailed view or pop-up.

Educational Context Popup: When the user interacts with the misinformation indicator, the app should display additional context. This could be a SwiftUI overlay or sheet that shows a short text explaining why the content was flagged (e.g. "This video claims guaranteed 200% returns. Guaranteed returns are often a scam sign – see [link] for more info."). The "[link]" could be a button that opens an in-app SafariWebView or the default browser to an educational resource (for example, an SEC or consumer finance article). The context data (explanation text and URL) will be provided by the AI analysis or a predefined mapping in the backend.

Video Upload Interface: Users need the ability to upload their own videos. The frontend will have an upload screen where a user can select a video from their library or record a new video (using the camera). We can use SwiftUI's PhotosPicker (available in iOS 16+) to choose a video file, or integrate a UIKit UIImagePickerController for video capture if needed. After selecting/recording, the video is sent to the backend (Firebase Storage) and a new entry is created in Firestore. The UI should show an upload progress indicator. Once uploaded, the video will appear in the feed (for the uploader, perhaps under their profile or in a global feed depending on design).

Authentication UI: (If authentication is required in MVP) FinShield can use Firebase Authentication for user accounts. We might allow anonymous usage for viewing the feed, but uploading a video or liking/commenting could require login. Firebase Auth supports Sign-in with Apple or Email/Password, which we can integrate via SwiftUI forms. This PRD assumes basic auth is in place (users sign up/in, and user ID is used to associate their uploads), though for an MVP, we could keep it simple.

Other UI Components: Navigation could be minimal (maybe a tab bar if we later add sections like a profile or settings). For MVP, the main screen is the feed. Possibly a separate screen for uploading or a floating "+" button like TikTok. A settings page might include toggles for content preferences or account management. All UI is built with SwiftUI for consistency and easier maintenance.

### 2.2 Backend (Firebase) Architecture

The backend for FinShield will rely on Firebase services: Firestore for database, Firebase Storage for video files, Firebase Authentication for user accounts, and Cloud Functions to run AI analysis. This serverless approach accelerates development and scales as needed. Key elements of backend design:

Firebase Project Setup: We will use a single Firebase project for the app. Firestore will store metadata and analysis results, Storage will hold the videos, and Auth will manage users. Security rules will be written to ensure proper access (e.g., users can only upload to their own account, read access to videos is public for the feed, etc.).

Firestore Data Model: Define collections for the main entities:

videos collection: Each document represents a video post. Fields might include:
- videoURL (link or path to the video file in Storage),
- thumbnailURL (optional, could be generated for preview),
- uploaderID (reference to users),
- description (caption text, if any, provided by uploader),
- transcript (text of the speech, filled in by the AI pipeline),
- isFlagged (bool, set true if misinformation detected),
- flagReasons (array of strings or a structured object describing why it was flagged),
- contextLink (URL to an educational resource to display),
- timestamp (upload time).

The transcript and analysis fields may initially be empty/null when the video is first uploaded and will be populated after processing. Alternatively, we might store transcript/analysis in a subcollection (e.g. videos/{videoId}/analysis) to keep the main document light and load it only when needed. For simplicity, adding fields to the main doc is fine for MVP.

users collection: Each user's profile info (name, email, etc.) and settings. (If we implement user accounts and profiles in MVP.) Not heavily used by the core feed, except for possibly showing the uploader's name.

(Optional for future) reports or flags: If we allow users to manually report misinformation or track AI flags separately. But since AI analysis is automatic, we might not need a separate collection for it; the info lives in the video doc.

(Optional) resources collection: A curated list of educational links/resources keyed by topic. For example, a doc for "Ponzi scheme" with a URL to an article about Ponzi schemes. The AI analysis could output a topic key which maps to one of these resources. This would make it easy to manage the educational links in the app via the database.

Firebase Storage: Used to store the actual video files uploaded by users. When a user uploads a video, the app will put the file in storage (e.g. under a path like videos/{userId}/{videoId}.mp4). We will enforce a maximum file size or duration (to control processing costs and playback performance – e.g. maybe 1 minute max length for videos). After uploading, the storage will return a download URL or we can use Firebase SDK to retrieve it; this URL is stored in the Firestore videos doc for others to stream. Security: the Storage rules can allow read access to all (if the content is public) or require auth. For MVP, assume the feed is public, so reads are allowed, writes require auth of uploader.

Cloud Functions (Node.js): This is where the AI pipeline can run securely. Instead of calling OpenAI/Anthropic directly from the app (which would expose API keys and be inefficient on mobile), we set up Firebase Cloud Functions to handle the heavy tasks asynchronously:

Speech-to-Text Function: Triggered when a new video is uploaded. We can use a Cloud Function triggered by a Firestore write (e.g., a new document in videos collection with a storage path) or by a Storage finalization event (file upload complete). The function will fetch the video (or its audio track) from Firebase Storage. It then calls a third-party speech-to-text API. We anticipate using OpenAI's Whisper API for transcription (via a REST call to OpenAI). Example: using OpenAI's audio transcription endpoint with the video's audio; Whisper is a state-of-the-art speech recognition model that should handle financial terminology well. If OpenAI is not preferred, alternatives include Google Cloud Speech-to-Text or AWS Transcribe, but Whisper's accuracy is a plus. The function will receive the transcribed text of the video's speech.

Misinformation Analysis Function: After getting the transcript, the pipeline calls an AI model (OpenAI GPT-4, GPT-3.5, or Anthropic Claude) to analyze the text. This can be done in the same function call as transcription (one function calls both APIs in sequence), or a separate function. We can craft a prompt for the LLM such as: "Analyze the following transcript of a finance-related video and determine if it contains any misleading or false financial claims. If yes, identify the suspicious statements and provide a brief explanation suitable for end-users, along with a reference or educational link about this topic." The LLM's response will include whether the content is flagged and the reasons. We might also maintain a list of known red-flag keywords/phrases (like "guaranteed returns", "double your money fast", etc.) to help pattern-match, but the LLM can handle context beyond keywords.

Writing Back Results: The function will then update the Firestore videos document with the analysis results. For instance, set transcript to the text, isFlagged to true/false, flagReasons with a summary (e.g. "Promises of 'guaranteed profit' which is often a scam indicator"), and contextLink maybe chosen from a predefined mapping. The educational link could either be generated by the AI (we could have the AI suggest a Wikipedia or government site link) or, safer, the function can decide based on the reason. (For example, if the reason mentions "multi-level marketing scam," the function could attach a link to an FTC page on MLM scams from the resources collection or a config.)

Using Cloud Functions ensures the OpenAI/Anthropic API keys are secure (stored as environment variables) and keeps heavy processing off the device. The functions can run asynchronously – the app doesn't wait for the response in real time; instead, it will get updated data via Firestore. We must handle errors (e.g. API failures) gracefully: perhaps set a field like analysisStatus to "failed" or "completed" so the app knows whether it can trust the analysis fields.

Realtime updates: The app can take advantage of Firestore's real-time listeners. For example, when showing a video, the client could listen to that video document for changes. If a video was just uploaded and is awaiting analysis, the overlay could initially indicate "Analyzing…" and then automatically update to show the result once the Firestore doc is updated by the function. This provides a smooth UX (no need for user to refresh). For videos already processed, the data is readily available.

Authentication: If using Firebase Auth, the backend rules will enforce that only authenticated users can upload videos (and perhaps require email verification to reduce spam). The Auth integration also means user-specific data (like a user's own uploads) can be queried. However, the core feed might be global/public for all users to browse.

Performance and Scalability: Firebase can scale to many concurrent users. We should be mindful to index any Firestore queries (e.g. if we query videos ordered by timestamp for the feed, ensure an index on timestamp). Video content delivery will be via CDN-backed Firebase Storage URLs, which should stream efficiently. The Cloud Functions need proper memory/timeout settings as processing video + AI might be slow; possibly use a higher-memory function instance or break tasks if needed. For MVP, a single function handling both transcription and analysis sequentially is simplest. If volume grows or we need faster throughput, we could pipeline (one function per task triggered in sequence) or integrate a queue system.

### 2.3 AI Pipeline for Speech-to-Text and Claim Detection

The AI component is central to FinShield's value. We leverage existing AI services to convert video audio into text and then analyze that text. The design of the AI pipeline is as follows:

Speech-to-Text (STT): As noted, we will use a third-party API like OpenAI Whisper or an equivalent to transcribe spoken words in the video. The input will be the audio track from the uploaded video. Implementation details:

If using OpenAI's Whisper API: the Cloud Function will send the audio content (possibly compressing to mp3 or wav) to OpenAI's /v1/audio/transcriptions endpoint. The response will be a JSON with the transcribed text. We need to consider language support (Whisper can handle multiple languages; for MVP we focus on English content unless we plan multi-language support).
If using an alternative (like Google Cloud STT), we'd use their Node.js client in the function to get text. Whisper is preferred for accuracy in finance terms.
The transcript text is then cleaned up (the API may include punctuation and casing already). We might limit the length if needed (but most videos are short, a minute of speech is fine for LLM input).

Content Analysis: Using a Large Language Model (LLM) via API to detect misinformation. We have two main choices mentioned: OpenAI or Anthropic:

OpenAI GPT-4/GPT-3.5: We can call the OpenAI Chat Completion API with a carefully crafted system/user prompt containing the transcript and asking for an analysis. GPT-4 would likely yield the best quality. The prompt can request a structured output, e.g. JSON listing flag: true/false, reasons: [list of reasons], suggestedLink: "URL". If using GPT-3.5, we ensure the prompt is clear due to its token limit and slightly lesser ability to follow complex instructions. We must also watch the token count; a 1-minute transcript (~150 words) plus analysis is well within limits. Cost is a factor (we'll monitor usage).

Anthropic Claude: Similarly, we could use Claude API with an appropriate prompt. Claude might handle longer transcripts if needed (it has a larger context window). Either choice can work; we might prefer OpenAI for its Whisper + GPT synergy. For MVP, we can implement with one (say OpenAI) and potentially swap or allow using either via config.

Detection logic: What constitutes "financial misinformation" will be defined in the prompt. For example, the prompt will instruct the AI to look for things like:
- Unrealistic returns or guarantees ("I made 1000% profit in a week guaranteed!"),
- Language that is common in scams ("no risk, all reward", "double your money, just pay a fee up front", "this secret investment hack…"),
- Unverified claims about financial products or markets (for instance false info about a stock or crypto),
- Encouragement of illegal or dubious schemes.

The AI should differentiate legitimate advice vs. misleading claims. We might instruct it to err on the side of caution (flag if unsure).

Output and Post-processing: The AI's response will be parsed by the Cloud Function. If the AI provides an explanation and a link, we use those. If it only provides analysis, our function might attach a generic link. For example, if a video is flagged for "guaranteed returns", we attach a link to an article on why guaranteed returns are a red flag. These links could be stored in Firestore resources as mentioned, or even a simple if/else in code for common cases. The explanation from the AI (or generated from known templates) will be stored so the app can show it in the overlay.

Overlays with Educational Links: The end result of the pipeline is that for a given video, we know whether it's flagged and why. The app, upon retrieving a video's data from Firestore, will see isFlagged=true and then display the overlay indicator. When the user taps for info, the app will show the explanation (e.g. "This video makes an extremely high return promise, which is a common sign of fraud.") and have a button to "Learn more". That button's URL (e.g. to an SEC page on investment scams) comes from the contextLink field. The user can tap it to open the link. We ensure these links are from reputable sources (government, established financial education sites).

Privacy and Accuracy: It's important to note that user-uploaded videos are being analyzed by third-party AI APIs. We will include in our privacy policy that audio is sent to these services. We should also handle cases where the AI might be unsure. Possibly categorize content as "safe" vs "flagged" vs "needs review". For MVP, a binary flag is fine. We won't automatically remove content; we just inform viewers. If the AI analysis fails (e.g., the speech was not transcribable or API errors), we might mark isFlagged=false by default (or set a special status) so that we do not wrongly flag something without evidence.

In summary, the technical architecture uses SwiftUI and AVKit on the frontend to present videos and overlays, Firebase as the backbone for data and file storage, and cloud AI services integrated via Firebase Functions to perform transcription and content analysis. The components communicate primarily through Firebase (upload triggers function; function updates Firestore; app listens to Firestore changes).

## 3. Checkpoints & Milestones (MVP Development Plan)

To build the MVP in an orderly way, we define a series of development checkpoints and milestones. Each milestone adds a set of features or completes a critical part of the app, allowing for iterative testing and validation:

### Milestone 0: Environment Setup Complete – (~Day 1)

Outcome: Development environment is verified by running a SwiftUI "Hello, World" app on simulator. Firebase is connected (the app can successfully call FirebaseApp.configure() without errors). This is covered in section 1 above.
Checkpoint: Xcode project created, Firebase project created, app runs with basic UI.

### Milestone 1: Basic UI Scaffold & Video Playback – (~Week 1)

Build the main feed UI with SwiftUI. For this milestone, use placeholder/dummy video content (e.g., include a sample MP4 in the bundle or use a test URL). Implement a VideoPlayer view full-screen and confirm a video plays and loops.
Implement the swipe navigation between videos. Perhaps start with two or three hardcoded video entries to swipe between. Ensure that swiping transitions smoothly and the previous video stops when off-screen (to free resources).
Basic overlay UI: Overlay a dummy caption or static UI elements on the video to confirm that ZStack layering works (for example, place a text "Sample Video 1" on top of the video). No actual analysis info yet, just the framework for overlays.
Checkpoint: You can swipe through a few videos in a TikTok-like fashion and they play correctly with UI elements on top.

### Milestone 2: Firebase Integration (Data & Auth) – (~Week 2)

Integrate real data via Firebase. Replace the hardcoded video list with data fetched from Firestore. Set up a videos collection in Firestore and manually add a few entries with video URLs (which could point to some publicly hosted test videos or Firebase Storage links if we upload them). In the app, use Firebase SDK to fetch this list and display the feed dynamically.
Implement basic Firebase Authentication if required for upload: e.g., allow Anonymous login or simple email sign-in just so we can associate an uploader ID. This could be optional at this stage if viewing doesn't require auth.
Ensure that the app properly reads from Firestore and streams video from the URLs. Use Firestore listeners for real-time update (for instance, if we change a video's metadata in console, it could reflect in app – not critical for now, but sets stage for real-time behavior).
Checkpoint: The app is now data-driven – videos shown are coming from the backend. Developers can add a new video document in Firestore and see it appear in the app without a recompile.

### Milestone 3: Video Upload Functionality – (~Week 3)

Implement the video upload UI in the app. Use a PhotosPicker to let a user select a video (or camera capture). On selection, get the file URL and upload it to Firebase Storage using the Firebase Storage SDK. Show upload progress (SwiftUI can show a ProgressView bound to upload task state).
Once upload completes, create a new document in Firestore videos collection with the metadata (storage download URL, uploader info, timestamp, etc.). For now, you can set isFlagged=false or leave analysis fields empty – the AI integration will come later.
(If Auth is in place) ensure that only logged-in users can see the upload option, and tag the uploaderID in the Firestore doc with Auth.auth().currentUser.uid.
Test by uploading a video through the app and then seeing it appear in the feed list (you may need to allow your Firestore security rules to let this write, or run the app with emulator/loose rules during development).
Checkpoint: A user can add a new video via the app, it uploads to backend, and then shows up in the feed. The feed now is dynamic and user-contributable.

### Milestone 4: AI Pipeline Integration (Backend) – (~Week 4-5)

Set up the Cloud Function for speech-to-text and analysis. Write a Firebase Cloud Function (Node.js runtime) that triggers on new video documents or storage uploads. (For development ease, you might call it manually with an HTTPS trigger first, then later change to onCreate trigger.)
In the function, use a placeholder or test call to OpenAI's API. Initially, you could test the OpenAI Whisper API with a fixed audio file to ensure the integration works (using curl or a small Node script). Then integrate into the function: fetch the uploaded video file (the function can use the admin SDK to get a download URL or directly stream the file from storage), send it to Whisper API, get transcript. Next, send the transcript to GPT-4 (or GPT-3.5) for analysis with a basic prompt. For the first test, you can log the results or store them in a test field.
Once the pipeline is working, have the function update the Firestore document with actual fields: transcript, isFlagged, flagReasons, contextLink. To avoid the function running multiple times on the same doc, you could have the client set an analysisStatus: "pending" when uploading and function sets it to "done" after processing, or use a separate subcollection to trigger (design choice). Simpler: use a Firestore onCreate trigger and the function only runs once per new video doc.
Test end-to-end: Upload a video via the app that contains a known financial scam phrase (e.g. a video of someone saying "I guarantee you will get rich quick"). Wait a few seconds for the Cloud Function to process. Then check Firestore — the new video doc should now have isFlagged=true and a reason like "Guarantee of riches with no risk" and perhaps a context link.
Checkpoint: The backend successfully processes an uploaded video and marks misinformation. We have effectively connected the pieces: storage -> function -> Firestore update.

### Milestone 5: Frontend Misinformation Overlay – (~Week 5)

Update the SwiftUI feed UI to reflect analysis results. The video item view should now read the isFlagged field and if true, show the warning icon or overlay banner on that video. Possibly, even if the transcript is available, we might display a snippet or allow the user to see it (for accessibility or additional clarity).
Implement the interaction for the user to tap the overlay. For example, if using an InfoButton or a custom Button with an info icon, attach a sheet presentation that shows the full explanation (flagReasons) and a link. Use Link or SafariView to open contextLink when tapped. Style the overlay to be noticeable but not overly intrusive (maybe a small icon that expands when tapped).
Ensure that videos without flags either show nothing special or maybe an unobtrusive indicator that it's verified/clear (not required, but could use a subtle "✔️ no issues found" in the info popup if we want to reinforce trust). That might be a nice-to-have; otherwise, no icon means no issues found.
Test with videos that you know will be flagged vs not flagged. You can simulate by manually flipping isFlagged in Firestore or altering the function's criteria. Make sure the overlay appears at the right times and the link opens properly.
Checkpoint: Users scrolling the feed will see misinformation warnings on the relevant videos and can tap to get more info. The core functionality of FinShield (flagging and informing) is now visible in the app.

### Milestone 6: Refinement and UX Improvements – (~Week 6 and beyond)

Clean up UI: make sure the video playback is smooth (pause videos when off-screen to save battery, etc.), and that the overlay doesn't hinder normal viewing (maybe hide the overlay icon after a few seconds and show on tap, similar to how controls hide; or always show a small icon – design can be tweaked).
Optimize performance: use Firestore query limits (load maybe the first X videos, and as user approaches end, load more). Ensure that the app isn't downloading too many videos at once. Possibly implement lazy loading of video content (only instantiate AVPlayer for the currently visible video and maybe one ahead).
Error handling: handle cases where a video fails to load (show a retry or skip), or if the analysis is pending/failed (e.g., overlay icon might show a question mark if analysis didn't complete).
Security review: double-check Firebase rules so that users cannot maliciously write isFlagged=false on their own video or tamper with others. Likely, normal users should not be able to write to isFlagged at all – only the Cloud Function (which runs with admin privileges) should set that. We can enforce with rules that only allow that field to be set if it's null prior (initial upload) and subsequent changes only by service (maybe via a specific security rule condition or by using Cloud Function with admin privileges bypassing rules).
UI polish: add any minor features if time permits, like a basic "like" button (not fully functional, just cosmetic for demo), or show the video uploader's name, etc., to mimic TikTok feel.
Checkpoint: The MVP is feature-complete and refined. The app can be tested by a small group for feedback.

Each milestone builds on the previous, ensuring that at any point we have a working app to demonstrate partially. By the end of Milestone 5, the core scenario (upload video -> AI flags it -> user sees warning) is done. Milestone 6 is about making the app feel smooth and production-ready.

## 4. Opinionated Technical Decisions

In building FinShield, several technical decisions need to be made where multiple approaches are possible. Here we outline the chosen approaches along with reasoning, covering video handling, AI integration, Firebase usage, and code organization:

### 4.1 Video Handling and Performance

Use AVKit/VideoPlayer for Simplicity: We choose to use SwiftUI's built-in VideoPlayer (wrapping AVPlayer) for video playback. This is the most straightforward way to play videos in SwiftUI, as opposed to building a custom player. It supports remote URLs and integrates well with SwiftUI's view updates. Using VideoPlayer also ensures we get native optimizations and UI behavior for free.

Continuous Playback and Preloading: TikTok's UX requires instant playback on swipe. We will preload the next video while the current is playing. One approach is to create multiple AVPlayer instances – one for current, one for next – and manage them in the ViewModel. As the user swipes, swap active players. We deliberately loop short videos for continuous engagement, which AVPlayer can do by setting actionAtItemEnd = .none and seeking to start on completion.

Video Caching: By default, AVPlayer will stream the video. We rely on iOS's caching (it will buffer some content). For better performance, we might limit video resolution (e.g., upload videos at 720p max to reduce bandwidth). If needed, in the future we could integrate an SDK or custom caching mechanism to store recently watched videos on device, but not in MVP scope.

Memory Management: Playing many videos can use significant memory. We'll make sure to release or reuse players for videos that are no longer on screen. SwiftUI's onDisappear for a video view can pause or stop the player. Also, large arrays of video data should be handled carefully; we might use pagination (fetch a batch, then fetch more) rather than loading 1000 videos at once.

### 4.2 AI Analysis Strategy

Off-device Processing: We opt to run speech-to-text and content analysis on the backend (Cloud Functions calling external APIs) rather than on-device. On-device AI (like running Whisper or a small model) is intriguing but would greatly increase app complexity and likely be too slow/heavy for phones, especially in SwiftUI which doesn't easily support long-running background threads for ML. Server-side ensures the iPhone's battery isn't drained by AI tasks and keeps the model logic maintainable on the server.

Choosing AI Models: We plan to use OpenAI's Whisper for transcription due to its high accuracy for conversational speech and finance jargon. For misinformation detection, OpenAI GPT-4 is preferred for its superior reasoning on complex input, with GPT-3.5 as a cost-effective alternative. If we find latency or cost issues, we might experiment with Anthropic Claude or even fine-tune a smaller model. Given the criticality of catching subtle misinformation, using a top-tier model initially is justified.

Prompt Engineering vs. Fine-tuning: Initially, we will solve the detection via prompt engineering with GPT-4/3.5. This allows rapid iteration (tweaking the prompt's instructions). For example, we'll instruct the model to be on the lookout for "too good to be true" claims and provide counter-evidence. If we later find repetitive patterns, we might fine-tune a model or use a classification approach. For MVP, a well-crafted prompt and the model's general knowledge should suffice.

Handling AI Limitations: LLMs might occasionally miss something or falsely flag truthful info. Our approach is to use them as an aid, not absolute arbiter. We will review some outputs during testing to adjust the prompt. Also, to avoid egregious errors, we could implement a simple keyword filter as backup – e.g., if the transcript contains certain obvious scam words and the AI didn't flag it, we might still flag it. This rule-based overlay can serve as a safety net.

Latency Management: Calling two APIs (transcription and then analysis) means the full pipeline might take several seconds per video. This is acceptable for now because analysis happens asynchronously – by the time a viewer sees a newly uploaded video, chances are the processing is done (unless they view it immediately after upload). We will inform uploaders that analysis might take e.g. up to 30 seconds to show results. If performance is an issue, we could look into parallelizing (transcribe and analyze in parallel using whisper's interim results) or using faster models at some accuracy cost.

### 4.3 Firebase Data Modeling and Performance

Data Structure Optimized for Feed: We structured Firestore documents to contain all info needed to render a video in the feed (URL, caption, flags, etc.) so that a single query can retrieve everything. This denormalized approach (as opposed to splitting transcript or analysis into separate documents) keeps the feed load simple – one query to videos gives us the list. The tradeoff is each video doc is larger, but transcripts are just text and not huge (maybe a few hundred characters). Firestore can handle documents up to 1MB, so even with analysis info we are fine. We should, however, exclude extremely large data from the main collection – for example, if we were storing full AI reasoning or a long article. In such cases, a separate collection or storage file would be better.

Indexes and Querying: For the feed, if we want the newest videos first, we will query videos ordered by timestamp descending. We'll ensure an index on timestamp. If we implement pagination/infinite scroll, we'll use query cursors (startAfter) to load subsequent pages.

Firebase Limits: Firestore has a limit of 1MB per document and a certain throughput per second per query. Our use (short text, moderate video entries) is unlikely to hit these in MVP. For a very active platform, we'd monitor read rates. Possibly we might need to shard the feed if write rates are very high (unlikely early on).

Security Rules: We will lock down writes appropriately. For instance, only allow creating a video entry if request.auth.uid == data.uploaderID and only if certain fields are being set (prevent users from setting isFlagged themselves). The Cloud Function, using admin SDK, can override and set flag fields. For read, since this is a public feed, we can allow any read on videos. But if we wanted to limit it (like only authenticated users can view), we'd adjust rules accordingly.

Firebase vs. Custom Server: We chose Firebase for speed of development. An alternative could have been a custom backend with a database and storage. Firebase gives us instant real-time sync, which is nice for updating the feed with analysis results. The decision is that, given the scope, Firebase sufficiently covers auth, storage, and DB, and the extra flexibility of a custom server wasn't needed yet.

### 4.4 Modular Code Structure and Maintainability

MVVM Architecture: We will follow a Model-View-ViewModel pattern with SwiftUI. Views (SwiftUI structs) will be as dumb as possible, just reflecting state. The business logic (like fetching from Firestore, uploading video, etc.) will reside in ViewModels (classes conforming to ObservableObject). For example, a FeedViewModel will manage loading the list of videos and updating the current index, an UploadViewModel will handle the upload process, and maybe an AuthViewModel for login state. These view models can be provided to views via @StateObject or @EnvironmentObject. This separation makes the code more testable and organized.

Services Layer: We'll implement specific service classes or utilities for interacting with external systems: e.g. FirebaseService (wrapping Firestore and Storage calls), and AIService or AnalysisService for calling the cloud function or APIs (though much of that logic is server-side, the client might still have to call a cloud function HTTP endpoint if we choose that route, or at least handle some result parsing). Having these in their own files (not hard-coded in the ViewModel) allows easier swapping (e.g. if we want to switch to a different backend later or mock them for tests).

Modular Files: Break down the SwiftUI views into components. For instance, a VideoCardView for the video player + overlays, a MisinformationOverlayView for the overlay content (so it can be reused or easily modified), etc. Keep each file focused (no massive SwiftUI view files with 1000 lines). Similarly for backend, although Cloud Functions is separate codebase (probably Node.js), we structure it with clear functions for each task (one for transcription, one for analysis), even if triggered in sequence.

State Management: Use Combine publishers (which come with @Published in ViewModels) to automatically update the UI on data changes. For example, when Firestore data is fetched or changed, the FeedViewModel.videos array updates, and the view refreshes to show new content. Real-time listener can directly update published properties. This reactive approach fits well with SwiftUI.

Extensibility: We anticipate future features, so we keep the code flexible. For instance, when adding "fact-check database integration" later, it might involve additional fields or calls – we should design the analysis result data structure in a way that can accommodate more info (maybe a list of flags instead of a single boolean, to allow multiple categories, etc.). By modularizing, adding new components or replacing implementations (like switching from OpenAI API to a custom ML model) will be easier.

### 4.5 Other Notable Decisions

Third-Party Libraries: We aim to minimize external dependencies. SwiftUI and Firebase cover most needs. We might use a library for richer video controls or caching if needed, but initially we try to do without to reduce complexity. For opening links in-app, we might use SwiftUI's Link or a small wrapper for SFSafariViewController (no heavy library needed).

Testing Approach: While not a primary focus of PRD, note that we should test the AI output with known cases. Possibly create a set of sample transcripts and run them through the analysis function to see if it flags correctly. This can be done with unit tests on the Cloud Function (or a separate script calling the OpenAI API) to refine the prompt. Similarly, UI tests on the feed swiping and overlay appearing will be done to ensure nothing breaks (Xcode's UI Test runner can simulate swipes).

App Store Compliance: Because we deal with user-generated content and identifying misinformation, we should ensure this aligns with App Store guidelines. We might need to provide a way for user to report content or appeal flags (maybe not in MVP, but keep in mind). Also, privacy labels need to disclose that user content is analyzed. From a technical standpoint, our design where all analysis is server-side means the app itself doesn't contain the AI models, just sends data out – which is fine but should be transparent to users.

By making these decisions, we ensure that FinShield's development is on a strong footing: leveraging high-level frameworks (SwiftUI, Firebase) for speed, using powerful AI services for the core functionality, and structuring code for future growth.

## 5. Potential Roadmap Extensions

FinShield's MVP focuses on audio transcription and text-based analysis of videos. There are many opportunities to enhance the product in future versions, both in terms of AI sophistication and user features. Below are some extensions we envision, beyond the initial scope:

### Video-based AI Analysis (Beyond Audio)

Currently, analysis is based only on what is spoken. In future updates, we can analyze visual content of the video. This may include:

Text in Video Frames: Use OCR on video frames to catch any text the creator has shown (e.g., on slides or captions within the video). Scammers might display phone numbers, URLs, or claims in text. Analyzing that text could help flag content that the audio missed. We could use APIs like Google Vision for text detection in frames or even Apple's Vision framework on-device to scan frames at intervals.

Image Analysis: If the video shows charts, money, or other symbols, computer vision could interpret those. For example, detecting a logo of a well-known company being used fraudulently, or recognizing deepfake faces if someone impersonates a famous financial advisor. These are complex tasks, but doable with advanced models (e.g., using deepfake detection algorithms).

Audio Tone Analysis: Apart from the literal transcript, analyze the tone or sentiment. A very pressuring or urgent tone might be a flag ("Act now or you'll miss out!" urgency could be a red flag). We could use acoustic analysis or simply have the LLM consider the style of language.

Multilingual Support: Extend speech-to-text and analysis to other languages. Financial scams are global; supporting at least a few major languages (Spanish, Chinese, etc.) by using language detection and then transcription in that language (Whisper can auto-detect and transcribe multilingual audio). The analysis prompt would then need to be adapted or the content translated for the LLM.

### Database-Backed Fact Verification

To strengthen the AI's conclusions, integrate external financial data sources for fact-checking. Potential enhancements:

Financial Data APIs: If a video mentions specific, verifiable facts (e.g., "Amazon's stock rose 50% last year" or "Inflation is currently 2%"), the app could automatically check those claims against data from an API (such as Yahoo Finance for stock prices, or official government data for economic indicators). This would move FinShield from just flagging subjective scam signals to also catching objectively false statements. The architecture might include a microservice or cloud function that queries these APIs and cross-checks with the transcript.

Knowledge Graph or Fact Database: Integrate with projects or databases that track common misinformation. For example, if a video pushes a known Ponzi scheme, cross-reference with a database of known scam schemes (maybe something maintained by regulatory bodies or community contributions). When a match is found, the app can display a tailored warning like "This video appears to reference [Scam X], which has been identified as a fraudulent scheme in the past." This could be partly manual (curating a list of known schemes and keywords) or automated via an AI knowledge base.

Community or Expert Input: Over time, FinShield could allow financial experts to provide verified answers or explanations. For instance, a flagged claim could be linked to a short article by a finance educator debunking it. This community content could live in a database that the overlay links to. Users might even submit links or explanations that are reviewed and then added to the app's knowledge repository.

### User Interaction and Feedback

Enhance how users engage with the content and the misinformation warnings:

User Reporting: Allow users to manually report a video as misleading if they spot something the AI missed. These reports could be fed into improving the AI (e.g., collected for retraining data) and also trigger a review by moderators. Conversely, users or content creators might dispute a flag – so a mechanism to handle that (perhaps an "Appeal" button that notifies admins) could be added.

Gamification of Learning: Since we are highlighting educational info, we could add features like quizzes or badges. For example, after viewing a flagged video and reading the context, the app could ask a quick question ("Why are guaranteed returns a red flag in investing?" with multiple choice). This makes the app not just about consuming content but also actively learning financial literacy. It's beyond MVP, but aligns with the mission.

Personalized Feed Filtering: In the future, users might have settings like "Hide videos flagged as misinformation" or "Show me educational content only". Some might want to avoid any possibly misleading content, others might be curious to see and learn from the flagged ones. We could allow filtering or tagging content accordingly.

### Scaling and Social Features

If FinShield grows:

Social Graph: Incorporate following mechanics (follow favorite content creators) and a profile page showing a user's uploads and perhaps their "reputation" or reliability score (if we rate how often their content is flagged or not). Creators could strive to have a "clean" record to show they share trustworthy advice.

Moderation & Admin Tools: Develop an admin dashboard where moderators can see all flagged videos, review them, and possibly remove content that is clearly fraudulent or dangerous. This goes hand-in-hand with making sure the platform isn't just automated; human oversight can catch what AI might miss or handle edge cases.

Monetization Considerations: If we ever allow promotions or ads, we'd need to ensure those are also vetted. Perhaps premium features could be offered, like a "verify my content" badge for creators who want an extra layer of credibility (their content could undergo additional checks).

### Technical Enhancements

Custom AI Models: In the long run, depending on scale and cost, we could train our own specialized model for financial misinformation (using the data we gather, plus external datasets). This could be a fine-tuned transformer model that we can host, reducing dependency on third-party APIs and lowering per-request cost.

Edge Caching of Analysis: To improve speed, some analysis could be done on-device for known patterns (a lightweight ML model that quickly scans for certain keywords before the server response arrives, to possibly show a "preliminary flag"). Or caching results for videos the user has seen so we don't call the AI again if they rewatch.

Platform Expansion: Develop an Android version or a web version of FinShield. Our architecture with Firebase and cloud functions would largely work cross-platform. The main effort would be rebuilding the frontend in Android (likely Kotlin with Jetpack Compose for similar UI, or Flutter/React Native as alternatives). This is a separate project but worth noting as a roadmap item if the iOS app proves valuable.

Each of these extensions can be planned as future phases. They aim to make FinShield more robust in combating misinformation and more engaging for users. Importantly, any new feature should continue the core philosophy: educate users and protect them from harmful financial misinformation, without heavily impeding the fun of browsing short videos. The technical foundation we set in the MVP (modular design, AI pipeline, and scalable backend) will allow us to explore these directions relatively easily as the product evolves.