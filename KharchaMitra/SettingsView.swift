import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @Environment(\.modelContext) private var modelContext

    @State private var showBackupSheet = false
    @State private var backupURL: URL?

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
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showBackupSheet) {
                if let backupURL = backupURL {
                    ShareSheet(activityItems: [backupURL])
                }
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
}

#Preview {
    SettingsView()
}