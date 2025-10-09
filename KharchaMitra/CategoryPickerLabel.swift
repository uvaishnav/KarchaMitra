import SwiftUI

struct CategoryPickerLabel: View {
    let category: Category

    var body: some View {
        HStack {
            Text(category.iconName)
            Text(category.name)
        }
    }
}
