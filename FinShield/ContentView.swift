import SwiftUI
import FirebaseAuth

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
