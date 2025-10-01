
import SwiftUI
import SwiftData

struct AddQuickActionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]

    @State private var name = ""
    @State private var icon = ""
    @State private var reason: String? = nil
    @State private var amount: Double? = nil
    @State private var selectedCategory: Category?

    var quickAction: QuickAction? = nil

    init(quickAction: QuickAction? = nil) {
        self.quickAction = quickAction
        _name = State(initialValue: quickAction?.name ?? "")
        _icon = State(initialValue: quickAction?.icon ?? "")
        _reason = State(initialValue: quickAction?.reason)
        _amount = State(initialValue: quickAction?.amount)
        _selectedCategory = State(initialValue: quickAction?.category)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Action Details")) {
                    TextField("Name", text: $name)
                    EmojiTextField(text: $icon, placeholder: "Select Icon")
                }

                Section(header: Text("Prefilled Expense Details (Optional)")) {
                    TextField("Reason", text: Binding(get: { reason ?? "" }, set: { reason = $0.isEmpty ? nil : $0 }))
                    TextField("Amount", value: $amount, format: .currency(code: "INR"))
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories) { category in
                            Text(category.name).tag(category as Category?)
                        }
                    }
                }
            }
            .navigationTitle(quickAction == nil ? "Add Quick Action" : "Edit Quick Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: saveQuickAction)
                }
            }
        }
    }

    private func saveQuickAction() {
        if let quickAction {
            quickAction.name = name
            quickAction.icon = icon
            quickAction.reason = reason
            quickAction.amount = amount
            quickAction.category = selectedCategory
        } else {
            let newQuickAction = QuickAction(name: name, icon: icon, reason: reason, amount: amount, category: selectedCategory)
            modelContext.insert(newQuickAction)
        }
        dismiss()
    }
}

#Preview {
    AddQuickActionView()
        .modelContainer(for: [QuickAction.self, Category.self], inMemory: true)
}
