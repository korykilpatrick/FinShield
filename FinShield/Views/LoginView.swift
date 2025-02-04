import SwiftUI

struct LoginView: View {
    var body: some View {
        Text("Hello World")
    }
}

/*
struct LoginView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to FinShield")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button(action: {
                authVM.signInAnonymously()
            }) {
                Text("Sign In Anonymously")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            // For a complete app, add Google/Apple/email sign–in buttons.
        }
        .padding()
    }
}
*/
