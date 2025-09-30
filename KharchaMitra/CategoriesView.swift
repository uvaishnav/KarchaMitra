
import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var categories: [Category]
    @State private var showingAddCategorySheet = false

    init() {}

    var body: some View {
        NavigationView {
            List {
                ForEach(categories.sorted(by: { $0.name < $1.name })) { category in
                    NavigationLink(destination: EditCategoryView(category: category)) {
                        HStack {
                            Text(category.iconName)
                                .font(.title)
                                .frame(width: 50)

                            VStack(alignment: .leading) {
                                Text(category.name)
                                    .font(.headline)
                                Text(category.type.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCategorySheet.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategorySheet) {
                AddCategoryView()
            }
        }
    }
}

#Preview {
    CategoriesView()
        .modelContainer(for: Category.self, inMemory: true)
}
