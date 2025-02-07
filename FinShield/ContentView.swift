import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject var authVM = AuthenticationViewModel()
    @StateObject var scrubbingManager = ScrubbingManager()

    var body: some View {
        NavigationView {
            if authVM.isSignedIn {
                ZStack {
                    VideoFeedView()
                        .environmentObject(scrubbingManager)
                    VStack {
                        Spacer()
                        BottomNavBarView()
                    }
                    .opacity(scrubbingManager.isScrubbing ? 0 : 1)
                    .edgesIgnoringSafeArea(.bottom)
                }
            } else {
                LoginView()
            }
        }
        // Provide authVM to all child views regardless of sign-in state.
        .environmentObject(authVM)
        .onAppear {
            print("[ContentView] onAppear => Checking auth state. isSignedIn = \(authVM.isSignedIn)")
        }
    }
}
