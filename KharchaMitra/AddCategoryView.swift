import SwiftUI

struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var icon: String = "❓"
    @State private var type: CategoryType = .need

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !icon.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Details"), footer: Text("Use UTR for expenses that don't affect your personal spending limit, like business costs or reimbursements.")) {
                    TextField("Category Name", text: $name)
                    Picker("Type", selection: $type) {
                        Text("Need").tag(CategoryType.need)
                        Text("Want").tag(CategoryType.want)
                        Text("UTR").tag(CategoryType.UTR)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Icon")) {
                    TextField("Emoji Icon", text: $icon)
                        .font(.largeTitle)
                        .multilineTextAlignment(.center)
                        .onChange(of: icon) { oldValue, newValue in
                            // Keep only the first emoji if multiple are entered
                            if newValue.count > 1 {
                                icon = String(newValue.prefix(1))
                            }
                        }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: saveCategory)
                        .disabled(!isFormValid)
                }
            }
        }
    }

    private func saveCategory() {
        let newCategory = Category(name: name, type: type, iconName: icon, colorHex: "#000000") // colorHex is unused for now
        modelContext.insert(newCategory)
        dismiss()
    }
}

#Preview {
    AddCategoryView()
}