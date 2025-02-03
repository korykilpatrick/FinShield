# FinShield – Development Environment Setup

This guide explains how to set up your macOS M4 development environment for FinShield.

## 1. Required Tools and Installation

1. **Xcode Installation**
   - Download and install the latest [Xcode](https://developer.apple.com/xcode/) from the Mac App Store or Apple Developer website.
   - Ensure Xcode is updated (e.g., Xcode 15+ for iOS 17 compatibility).
   - Install Command Line Tools via **Xcode > Preferences > Locations**.

2. **SwiftUI Project Setup**
   - Create a new iOS App project in Xcode using the **App** template.
   - Choose **SwiftUI** as the interface and **Swift** as the language.
   - Name the project “FinShield” and configure code signing (Apple ID for free provisioning is acceptable).

3. **Dependency Management**
   - **Swift Package Manager (SPM)** (Preferred):
     - In Xcode, navigate to *File > Add Packages...*.
     - Add the Firebase Swift SDK packages (Firebase/Auth, Firebase/Firestore, Firebase/Storage, etc.).
     
4. **Firebase SDK Integration**
   - Create a Firebase project on the [Firebase Console](https://console.firebase.google.com/) named “FinShield.”
   - Register your iOS app with the Firebase project (using your app’s bundle ID).
   - Download the `GoogleService-Info.plist` file and add it to your Xcode project.
   - Initialize Firebase in your app by calling `FirebaseApp.configure()` in your App’s initializer or via an AppDelegate.

## 2. "Hello, World" Milestone

1. Open `ContentView.swift` and modify the body:
   ```swift
   import SwiftUI

   struct ContentView: View {
       var body: some View {
           Text("Hello, FinShield!")
               .font(.largeTitle)
               .padding()
       }
   }
2. Build and run the app on an iOS Simulator (e.g., iPhone 15).
3. Verify that the “Hello, FinShield!” message displays correctly.

This confirms your environment is properly set up for FinShield development.