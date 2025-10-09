import SwiftUI
import SwiftData

struct EditRecurringExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var template: RecurringExpenseTemplate
    @Query var categories: [Category]

    @State private var amount: Double
    @State private var selectedCategory: Category?
    @State private var reason: String

    private var isFormValid: Bool {
        amount > 0 && !reason.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(template: RecurringExpenseTemplate) {
        self.template = template
        _amount = State(initialValue: template.amount)
        _selectedCategory = State(initialValue: template.category)
        _reason = State(initialValue: template.reason)
    }

    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Amount", value: $amount, format: .currency(code: "INR"))
                    .keyboardType(.decimalPad)
                
                Picker("Category", selection: $selectedCategory) {
                    Text("None").tag(nil as Category?)
                    ForEach(categories.sorted(by: { $0.name < $1.name })) { category in
                        HStack {
                            Text(category.iconName ?? "📦")
                            Text(category.name).foregroundColor(.primary)
                        }.tag(category as Category?)
                    }
                }

                TextField("Reason", text: $reason)
            }
        }
        .navigationTitle("Edit Recurring Payment")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save", action: save)
                    .disabled(!isFormValid)
            }
        }
    }

    private func save() {
        template.amount = amount
        template.category = selectedCategory
        template.reason = reason
        dismiss()
    }
}
