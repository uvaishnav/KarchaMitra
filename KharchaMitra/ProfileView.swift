import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query var settings: [UserSettings]
    private var userSettings: UserSettings? {
        // There should only be one settings object
        settings.first
    }
    
    @State private var editableLimit: Double = 0

    var body: some View {
        NavigationView {
            Form { // Using Form for better styling of sections
                Section(header: Text("Financial Settings")) {
                    HStack {
                        Text("Monthly Limit")
                        TextField("Amount", value: $editableLimit, format: .currency(code: "INR"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("App Management")) {
                    NavigationLink(destination: CategoriesView()) {
                        Label("Categories", systemImage: "list.bullet")
                    }
                    
                    NavigationLink(destination: RecurringPaymentsListView()) {
                        Label("Recurring Payments", systemImage: "arrow.2.circlepath")
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        // Universal dismiss keyboard action
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .onAppear {
                if let limit = userSettings?.expenseLimit {
                    editableLimit = limit
                }
            }
            .onChange(of: editableLimit) { oldValue, newValue in
                if let userSettings = userSettings {
                    userSettings.expenseLimit = newValue
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}