import Foundation
import FirebaseAuth

class AuthenticationViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false
    
    init() {
        self.isSignedIn = Auth.auth().currentUser != nil
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            self?.isSignedIn = (user != nil)
        }
    }
    
    func signInAnonymously() {
        Auth.auth().signInAnonymously { [weak self] result, error in
            if let error = error {
                print("Anon sign-in failed: \(error.localizedDescription)")
            } else {
                self?.isSignedIn = true
            }
        }
    }
    
    func createUser(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("Create user failed: \(error.localizedDescription)")
            } else {
                self?.isSignedIn = true
            }
        }
    }

    func signInWithEmail(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("Email sign-in failed: \(error.localizedDescription)")
            } else {
                self?.isSignedIn = true
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isSignedIn = false
        } catch {
            print("Sign out error: \(error.localizedDescription)")
        }
    }
}
