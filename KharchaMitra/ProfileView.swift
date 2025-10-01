import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query var settings: [UserSettings]
    @Query var categories: [Category]
    @Query var templates: [RecurringExpenseTemplate]
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    @State private var editableLimit: Double = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        Text("User Name") // Placeholder
                            .font(.title.weight(.bold))
                    }
                    .padding(.vertical)

                    // Financial Settings Card
                    DashboardCard {
                        VStack {
                            Text("Financial Settings")
                                .font(.headline).fontWeight(.medium)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                            
                            Divider()
                            
                            HStack {
                                Text("Monthly Limit")
                                    .padding(.leading)
                                Spacer()
                                TextField("Amount", value: $editableLimit, format: .currency(code: "INR"))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .padding(.trailing)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal)

                    // App Management Card
                    DashboardCard {
                        VStack(alignment: .leading) {
                            Text("App Management")
                                .font(.headline).fontWeight(.medium)
                                .padding([.leading, .top, .bottom])
                            
                            Divider()
                            
                            NavigationLink(destination: CategoriesView()) {
                                rowView(title: "Categories", icon: "list.bullet", count: categories.count)
                            }
                            
                            Divider().padding(.leading)
                            
                            NavigationLink(destination: RecurringPaymentsListView()) {
                                rowView(title: "Recurring Payments", icon: "arrow.2.circlepath", count: templates.count)
                            }
                            
                            Divider().padding(.leading)

                            NavigationLink(destination: CustomizeQuickActionsView()) {
                                rowView(title: "Quick Actions", icon: "bolt.fill", count: nil)
                            }
                            
                            Divider().padding(.leading)

                            NavigationLink(destination: SettingsView()) {
                                rowView(title: "Settings", icon: "gearshape.fill", count: nil)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
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
    
    @ViewBuilder
    private func rowView(title: String, icon: String, count: Int?) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundColor(.primary)
            Spacer()
            if let count {
                Text("\(count)")
                    .foregroundColor(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserSettings.self, Category.self, RecurringExpenseTemplate.self], inMemory: true)
}
