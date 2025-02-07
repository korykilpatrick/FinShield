import SwiftUI

// Simple placeholder modifier for custom placeholder styling.
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
            ZStack(alignment: alignment) {
                placeholder().opacity(shouldShow ? 1 : 0)
                self
            }
        }
}

struct LoginView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @State private var isLoginMode: Bool = true
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var handle = ""
    @State private var isLoading = false
    @State private var showPassword = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
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
                    
                    // Form Fields
                    VStack(spacing: 15) {
                        if !isLoginMode {
                            // Sign Up fields: Display Name and @handle.
                            TextField("", text: $displayName)
                                .placeholder(when: displayName.isEmpty) {
                                    Text("Display Name")
                                        .foregroundColor(Color(white: 0.4))
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .foregroundColor(.black)
                            
                            TextField("", text: $handle)
                                .placeholder(when: handle.isEmpty) {
                                    Text("handle")
                                        .foregroundColor(Color(white: 0.4))
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .foregroundColor(.black)
                        }
                        
                        // Email field.
                        TextField("", text: $email)
                            .placeholder(when: email.isEmpty) {
                                Text("Email")
                                    .foregroundColor(Color(white: 0.4))
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .foregroundColor(.black)
                        
                        // Password field.
                        if showPassword {
                            TextField("", text: $password)
                                .placeholder(when: password.isEmpty) {
                                    Text("Password")
                                        .foregroundColor(Color(white: 0.4))
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .foregroundColor(.black)
                        } else {
                            SecureField("", text: $password)
                                .placeholder(when: password.isEmpty) {
                                    Text("Password")
                                        .foregroundColor(Color(white: 0.4))
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Buttons
                    if isLoginMode {
                        Button(action: {
                            isLoading = true
                            authVM.signInWithEmail(email: email, password: password)
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "envelope")
                                        .font(.title3)
                                    Text("Login")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .disabled(isLoading)
                        
                        // Toggle to Sign Up mode.
                        Button(action: {
                            withAnimation {
                                isLoginMode = false
                            }
                        }) {
                            Text("Sign Up")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    } else {
                        // Sign Up mode: Show only the Sign Up button.
                        Button(action: {
                            isLoading = true
                            authVM.createUser(email: email, password: password, displayName: displayName, handle: handle)
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "person.badge.plus")
                                        .font(.title3)
                                    Text("Sign Up")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .disabled(isLoading)
                        
                        // Toggle back to Login mode.
                        Button(action: {
                            withAnimation {
                                isLoginMode = true
                            }
                        }) {
                            Text("Already have an account? Login")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Display authentication errors if any.
                    if let errorMessage = authVM.authError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
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
                    
                    // Anonymous Sign In Button.
                    Button(action: {
                        withAnimation { isLoading = true }
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
                    
                    // Terms and Privacy
                    VStack(spacing: 10) {
                        Text("By continuing, you agree to our")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 3) {
                            Button("Terms of Service") { }
                            Text("and")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Button("Privacy Policy") { }
                        }
                        .font(.footnote)
                    }
                    .padding(.top)
                }
                .padding(.horizontal)
            }
        }
        .onReceive(authVM.$authError) { newError in
            if newError != nil { isLoading = false }
        }
    }
}
