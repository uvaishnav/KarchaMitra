import SwiftUI

struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var icon: String = ""
    @State private var type: CategoryType = .need

    var onCategoryAdded: ((Category) -> Void)?

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !icon.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    init(onCategoryAdded: ((Category) -> Void)? = nil) {
        self.onCategoryAdded = onCategoryAdded
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
                    EmojiTextField(text: $icon, placeholder: "Select Icon")
                        .multilineTextAlignment(.center)
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
        let newCategory = Category(name: name, type: type, iconName: icon, colorHex: randomHexColor())
        modelContext.insert(newCategory)
        onCategoryAdded?(newCategory)
        dismiss()
    }
    
    private func randomHexColor() -> String {
        let red = Int.random(in: 0...255)
        let green = Int.random(in: 0...255)
        let blue = Int.random(in: 0...255)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

#Preview {
    AddCategoryView()
}