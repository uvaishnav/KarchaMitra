import SwiftUI
import SwiftData

struct RecurringPaymentsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecurringExpenseTemplate.reason) private var templates: [RecurringExpenseTemplate]

    var body: some View {
        List {
            ForEach(templates) { template in
                NavigationLink(destination: EditRecurringExpenseView(template: template)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(template.reason)
                                .font(.headline)
                            Text(template.category?.name ?? "Uncategorized")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(template.amount.toCurrency())
                    }
                }
            }
            .onDelete(perform: deleteTemplates)
        }
        .navigationTitle("Recurring Payments")
        .toolbar {
            EditButton()
        }
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for offset in offsets {
            let template = templates[offset]
            modelContext.delete(template)
        }
    }
}

#Preview {
    RecurringPaymentsListView()
        .modelContainer(for: [RecurringExpenseTemplate.self, Category.self], inMemory: true)
}
