
import SwiftUI
import SwiftData

struct CustomizeQuickActionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var quickActions: [QuickAction]
    @State private var showingAddQuickAction = false
    @State private var quickActionToEdit: QuickAction?

    var body: some View {
        NavigationView {
            List {
                ForEach(quickActions) { action in
                    Button(action: { quickActionToEdit = action }) {
                        HStack {
                            Text(action.icon)
                                .font(.largeTitle)
                            VStack(alignment: .leading) {
                                Text(action.name)
                                    .font(.headline)
                                if let reason = action.reason, !reason.isEmpty {
                                    Text("Reason: \(reason)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if let amount = action.amount {
                                    Text("Amount: \(amount, specifier: "%.2f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if let category = action.category {
                                    Text("Category: \(category.name)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .onDelete(perform: deleteQuickAction)
            }
            .navigationTitle("Customize Quick Actions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddQuickAction = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddQuickAction) {
                AddQuickActionView()
            }
            .sheet(item: $quickActionToEdit) { action in
                AddQuickActionView(quickAction: action)
            }
        }
    }

    private func deleteQuickAction(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(quickActions[index])
            }
        }
    }
}

#Preview {
    CustomizeQuickActionsView()
        .modelContainer(for: [QuickAction.self, Category.self], inMemory: true)
}
