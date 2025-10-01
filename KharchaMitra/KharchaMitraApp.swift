//
//  KharchaMitraApp.swift
//  KharchaMitra
//
//  Created by Vaishnav Uppalapati on 04/09/25.
//

import SwiftUI
import SwiftData

@main
struct KharchaMitraApp: App {
    
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self,
            Category.self,
            SharedParticipant.self,
            UserSettings.self,
            Settlement.self,
            RecurringExpenseTemplate.self,
            QuickAction.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                
        }
        .modelContainer(sharedModelContainer)
    }
}
