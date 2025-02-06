import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject var authVM = AuthenticationViewModel()
    
    var body: some View {
        NavigationView {
            if authVM.isSignedIn {
                ZStack {
                    VideoFeedView()
                    VStack {
                        Spacer()
                        BottomNavBarView()
                    }
                    .edgesIgnoringSafeArea(.bottom)
                }
            } else {
                LoginView().environmentObject(authVM)
            }
        }
    }
}
