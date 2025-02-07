import SwiftUI
import FirebaseAuth

struct BottomNavBarView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel

    var body: some View {
        HStack {
            navButton(icon: "house", title: "Home") {
                print("[BottomNavBarView] Home tapped.")
            }
            Spacer()
            navButton(icon: "person.2", title: "Friends") {
                print("[BottomNavBarView] Friends tapped.")
            }
            Spacer()
            Button(action: {
                print("[BottomNavBarView] Plus button tapped.")
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            Spacer()
            navButton(icon: "tray", title: "Inbox") {
                print("[BottomNavBarView] Inbox tapped.")
            }
            Spacer()
            if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                navButton(icon: "person.crop.circle", title: "Sign In") {
                    authVM.signOut()
                }
            } else {
                navButton(icon: "person.crop.circle", title: "Profile") {
                    print("[BottomNavBarView] Profile tapped.")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .padding(.bottom, 10)
        .background(Color.black)
        .onAppear {
            print("[BottomNavBarView] onAppear => rendering.")
        }
    }
    
    private func navButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
}
