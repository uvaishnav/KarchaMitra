import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @Environment(\.modelContext) private var modelContext
    @Query var settings: [UserSettings]

    @State private var showBackupSheet = false
    @State private var backupURL: URL?
    @State private var showResetAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Security")) {
                    Toggle("Enable App Lock", isOn: $isAppLockEnabled)
                        .accessibilityHint(Text("Requires Face ID or Touch ID to open the app."))
                }

                Section(header: Text("Data Management")) {
                    Button("Backup Data", systemImage: "arrow.up.doc", action: triggerBackup)
                        .accessibilityHint(Text("Saves a copy of your app data."))
                    
                    Button("Reset Saving Buffer", systemImage: "arrow.counterclockwise.circle", role: .destructive, action: {
                        showResetAlert = true
                    })
                    .accessibilityHint(Text("Resets your accumulated saving buffer to zero."))
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showBackupSheet) {
                if let backupURL = backupURL {
                    ShareSheet(activityItems: [backupURL])
                }
            }
            .alert("Are you sure?", isPresented: $showResetAlert) {
                Button("Reset Buffer", role: .destructive, action: resetSavingBuffer)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will reset your Saving Buffer to zero. This action cannot be undone.")
            }
        }
    }

    private func triggerBackup() {
        guard let storeURL = modelContext.container.configurations.first?.url else {
            print("Could not find SwiftData store URL.")
            return
        }
        self.backupURL = storeURL
        self.showBackupSheet = true
    }
    
    private func resetSavingBuffer() {
        if let userSettings = settings.first {
            userSettings.savingBuffer = 0.0
        }
    }
}

#Preview {
    SettingsView()
}