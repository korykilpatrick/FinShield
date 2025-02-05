import SwiftUI
import FirebaseAuth

// This is the main view that will be displayed when the app is opened. Lets start with a hello world.

struct ContentView: View {
    @StateObject var authVM = AuthenticationViewModel()
    
    init() {
        print("ContentView initialized")
    }

    var body: some View {
        NavigationView {
            VStack {
                if authVM.isSignedIn {
                    VideoFeedView()
                } else {
                    LoginView().environmentObject(authVM)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray)
        }
    }
}
