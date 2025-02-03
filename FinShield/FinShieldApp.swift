//
//  FinShieldApp.swift
//  FinShield
//
//  Created by Kory Kilpatrick on 2/3/25.
//

import SwiftUI

@main
struct FinShieldApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
