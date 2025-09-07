import SwiftUI
import SwiftData

struct EditCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var category: Category

    @State private var name: String = ""
    @State private var icon: String = ""
    @State private var type: CategoryType = .need
    @State private var showingDeleteAlert = false

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !icon.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(category: Category) {
        self.category = category
        _name = State(initialValue: category.name)
        _icon = State(initialValue: category.iconName)
        _type = State(initialValue: category.type)
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
                            if newValue.count > 1 {
                                icon = String(newValue.prefix(1))
                            }
                        }
                }
                
                Section {
                    Button("Delete Category", role: .destructive) {
                        showingDeleteAlert = true
                    }
                }
            }
            .navigationTitle("Edit Category")
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
            .alert("Delete Category?", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive, action: deleteCategory)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this category? This action cannot be undone.")
            }
        }
    }

    private func saveCategory() {
        category.name = name
        category.iconName = icon
        category.type = type
        dismiss()
    }
    
    private func deleteCategory() {
        modelContext.delete(category)
        dismiss()
    }
}