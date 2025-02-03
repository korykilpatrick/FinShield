//
//  ContentView.swift
//  FinShield
//
//  Created by Kory Kilpatrick on 2/3/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct ContentView: View {
    @State private var connectionMessage = "Checking Firebase connection..."
    @State private var isConnected = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("FinShield")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(connectionMessage)
                .foregroundColor(isConnected ? .green : .orange)
                .multilineTextAlignment(.center)
                .padding()
            
            if isConnected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 50))
            }
        }
        .padding()
        .onAppear {
            testFirebaseConnection()
        }
    }
    
    private func testFirebaseConnection() {
        let db = Firestore.firestore()
        // Try to access a collection to verify connection
        db.collection("test").document("connection").getDocument { (document, error) in
            if let error = error {
                connectionMessage = "Firebase Error: \(error.localizedDescription)"
                isConnected = false
            } else {
                connectionMessage = "Successfully connected to Firebase! 🎉"
                isConnected = true
            }
        }
    }
}

#Preview {
    ContentView()
}
