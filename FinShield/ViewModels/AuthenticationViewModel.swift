import Foundation
import FirebaseAuth

class AuthenticationViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var authError: String? = nil

    init() {
        self.isSignedIn = Auth.auth().currentUser != nil
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            self?.isSignedIn = (user != nil)
        }
    }
    
    func signInAnonymously() {
        Auth.auth().signInAnonymously { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.authError = error.localizedDescription
                    print("Anon sign-in failed: \(error.localizedDescription)")
                } else {
                    self?.isSignedIn = true
                    self?.authError = nil
                }
            }
        }
    }
    
    func createUser(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.authError = error.localizedDescription
                    print("Create user failed: \(error.localizedDescription)")
                } else {
                    self?.isSignedIn = true
                    self?.authError = nil
                }
            }
        }
    }
    
    func signInWithEmail(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.authError = error.localizedDescription
                    print("Email sign-in failed: \(error.localizedDescription)")
                } else {
                    self?.isSignedIn = true
                    self?.authError = nil
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isSignedIn = false
            self.authError = nil
        } catch {
            print("Sign out error: \(error.localizedDescription)")
        }
    }
}
