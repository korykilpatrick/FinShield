import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthenticationViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var authError: String? = nil

    init() {
        self.isSignedIn = Auth.auth().currentUser != nil
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isSignedIn = (user != nil)
        }
    }
    
    // Updated createUser function accepting both displayName and handle.
    func createUser(email: String, password: String, displayName: String, handle: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.authError = error.localizedDescription
                    print("Create user failed: \(error.localizedDescription)")
                } else if let user = result?.user {
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = displayName
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print("Profile update error: \(error.localizedDescription)")
                        }
                    }
                    // Save both displayName and handle in Firestore.
                    let data: [String: Any] = [
                        "displayName": displayName,
                        "handle": handle
                    ]
                    Firestore.firestore().collection("users").document(user.uid).setData(data) { error in
                        if let error = error {
                            print("Error saving user data: \(error.localizedDescription)")
                        }
                    }
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
