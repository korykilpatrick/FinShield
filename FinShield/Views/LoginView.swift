import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showPassword = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Logo and Title
                    VStack(spacing: 15) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .symbolRenderingMode(.hierarchical)
                        
                        Text("Welcome to FinShield")
                            .font(.system(size: 32, weight: .bold))
                        
                        Text("Secure your financial future")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                    
                    // Sign in options
                    VStack(spacing: 20) {
                        // Social Sign in Buttons
                        Button(action: {
                            // Implement Apple Sign In
                        }) {
                            HStack {
                                Image(systemName: "apple.logo")
                                    .font(.title3)
                                Text("Continue with Apple")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                        }
                        
                        Button(action: {
                            // Implement Google Sign In
                        }) {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                    .font(.title3)
                                Text("Continue with Google")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                        }
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.secondary.opacity(0.3))
                            Text("or")
                                .foregroundColor(.secondary)
                                .font(.footnote)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.secondary.opacity(0.3))
                        }
                        
                        // Anonymous Sign In
                        Button(action: {
                            withAnimation {
                                isLoading = true
                            }
                            authVM.signInAnonymously()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "person.fill.questionmark")
                                        .font(.title3)
                                    Text("Continue Anonymously")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 5)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal)
                    
                    // Terms and Privacy
                    VStack(spacing: 10) {
                        Text("By continuing, you agree to our")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 3) {
                            Button("Terms of Service") {
                                // Handle terms action
                            }
                            Text("and")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Button("Privacy Policy") {
                                // Handle privacy action
                            }
                        }
                        .font(.footnote)
                    }
                    .padding(.top)
                }
                .padding(.horizontal)
            }
        }
    }
}

// Preview
#Preview {
    LoginView()
        .environmentObject(AuthenticationViewModel())
}
