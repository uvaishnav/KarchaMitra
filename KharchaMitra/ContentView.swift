//
//  ContentView.swift
//  KharchaMitra
//
//  Created by Vaishnav Uppalapati on 04/09/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @State private var isUnlocked = false
    @State private var selectedTab = 0
    
    private let authService = AuthenticationService()

    var body: some View {
        Group {
            if !isAppLockEnabled || isUnlocked {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)

                    AnalysisView()
                        .tabItem {
                            Label("Analysis", systemImage: "chart.pie.fill")
                        }
                        .tag(1)

                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle.fill")
                        }
                        .tag(2)

                    HistoryView()
                        .tabItem {
                            Label("History", systemImage: "clock.fill")
                        }
                        .tag(3)
                }
            } else {
                LockedView(onUnlock: authenticate)
            }
        }
        .onAppear(perform: checkForAuthentication)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Re-authenticate when the app enters the foreground
            if isAppLockEnabled && isUnlocked {
                isUnlocked = false
            }
            checkForAuthentication()
        }
    }
    
    private func checkForAuthentication() {
        if isAppLockEnabled {
            authenticate()
        }
    }
    
    private func authenticate() {
        authService.authenticate { success in
            if success {
                isUnlocked = true
            }
        }
    }
}

#Preview {
    ContentView()
}
