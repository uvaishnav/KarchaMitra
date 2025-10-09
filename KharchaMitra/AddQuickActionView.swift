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
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var formAppear = false

    var quickAction: QuickAction? = nil
    
    private let suggestedIcons = ["☕", "🍕", "🚕", "💇", "🎬", "🏋️", "🎮", "📱", "👕", "🍔", "⛽", "🛒", "💊", "✈️", "🎵"]
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !icon.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(quickAction: QuickAction? = nil) {
        self.quickAction = quickAction
        _name = State(initialValue: quickAction != nil ? quickAction!.name : "")
        _icon = State(initialValue: quickAction != nil ? quickAction!.icon : "")
        _reason = State(initialValue: quickAction?.reason)
        _amount = State(initialValue: quickAction?.amount)
        _selectedCategory = State(initialValue: quickAction?.category)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.secondaryBackground,
                        Color.tertiaryBackground.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.lg) {
                        // Preview Card
                        QuickActionPreviewCard(
                            name: name.isEmpty ? "Action Name" : name,
                            icon: icon.isEmpty ? "⚡" : icon,
                            amount: amount,
                            category: selectedCategory
                        )
                        .scaleEffect(formAppear ? 1.0 : 0.9)
                        .opacity(formAppear ? 1.0 : 0.0)
                        
                        // Basic Details
                        ModernFormCard(title: "Action Details", icon: "bolt.circle.fill") {
                            VStack(spacing: AppSpacing.md) {
                                // Name Input
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Label("Action Name", systemImage: "textformat")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textSecondary)
                                    
                                    TextField("e.g., Morning Coffee, Taxi", text: $name)
                                        .font(.body)
                                        .padding(AppSpacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                                .fill(Color.secondaryBackground)
                                        )
                                }
                                
                                // Icon Selection
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Label("Choose Icon", systemImage: "face.smiling.fill")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textSecondary)
                                    
                                    if !icon.isEmpty {
                                        Text(icon)
                                            .font(.system(size: 48))
                                            .frame(maxWidth: .infinity)
                                            .padding(AppSpacing.md)
                                            .background(
                                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                                    .fill(Color.brandMagenta.opacity(0.1))
                                            )
                                    }
                                    
                                    // Icon Grid
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: AppSpacing.sm) {
                                        ForEach(suggestedIcons, id: \.self) { emoji in
                                            Button(action: { icon = emoji }) {
                                                Text(emoji)
                                                    .font(.system(size: 28))
                                                    .frame(width: 50, height: 50)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: AppCornerRadius.small)
                                                            .fill(icon == emoji ? Color.brandMagenta.opacity(0.2) : Color.secondaryBackground)
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: AppCornerRadius.small)
                                                            .stroke(icon == emoji ? Color.brandMagenta : Color.clear, lineWidth: 2)
                                                    )
                                            }
                                            .buttonStyle(ScaleButtonStyle())
                                        }
                                    }
                                    
                                    // Custom Input
                                    EmojiTextField(text: $icon, placeholder: "Or enter custom emoji")
                                        .font(.title3)
                                        .multilineTextAlignment(.center)
                                        .padding(AppSpacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                                .fill(Color.secondaryBackground)
                                        )
                                }
                            }
                        }
                        .scaleEffect(formAppear ? 1.0 : 0.95)
                        .opacity(formAppear ? 1.0 : 0.0)
                        
                        // Prefilled Details (Optional)
                        ModernFormCard(title: "Pre-fill Expense", icon: "doc.text.fill") {
                            VStack(spacing: AppSpacing.md) {
                                HStack(spacing: AppSpacing.xs) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.infoBlue)
                                    Text("These values will auto-fill when using this action")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Reason
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Label("Reason (Optional)", systemImage: "text.alignleft")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textSecondary)
                                    
                                    TextField("e.g., Morning Coffee", text: Binding(
                                        get: { reason ?? "" },
                                        set: { reason = $0.isEmpty ? nil : $0 }
                                    ))
                                    .font(.body)
                                    .padding(AppSpacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                            .fill(Color.secondaryBackground)
                                    )
                                }
                                
                                // Amount
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Label("Amount (Optional)", systemImage: "indianrupeesign.circle")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textSecondary)
                                    
                                    TextField("Amount", value: $amount, format: .currency(code: "INR"))
                                        .keyboardType(.decimalPad)
                                        .font(.system(.body, design: .rounded))
                                        .monospacedDigit()
                                        .padding(AppSpacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                                .fill(Color.secondaryBackground)
                                        )
                                }
                                
                                // Category
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Label("Category (Optional)", systemImage: "tag")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textSecondary)
                                    
                                    Picker(selection: $selectedCategory) {
                                        Text("None").tag(nil as Category?)
                                        ForEach(categories.sorted(by: { $0.name < $1.name })) { category in
                                            HStack {
                                                Text(category.iconName ?? "📦")
                                                Text(category.name).foregroundColor(.primary)
                                            }.tag(category as Category?)
                                        }
                                    } label: {
                                        HStack {
                                            if let selectedCategory {
                                                Text(selectedCategory.iconName ?? "📦")
                                                Text(selectedCategory.name)
                                            } else {
                                                Text("None")
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity)
                                    .padding(AppSpacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                            .fill(Color.secondaryBackground)
                                    )
                                }
                            }
                        }
                        .scaleEffect(formAppear ? 1.0 : 0.95)
                        .opacity(formAppear ? 1.0 : 0.0)
                        
                        // Save Button
                        Button(action: saveQuickAction) {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text(quickAction == nil ? "Create Action" : "Update Action")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                                    .fill(isFormValid ? AnyShapeStyle(Color.primaryGradient) : AnyShapeStyle(Color.gray.opacity(0.3)))
                                    .glowShadow(color: isFormValid ? Color.brandMagenta : Color.clear)
                            )
                        }
                        .disabled(!isFormValid)
                        .padding(.top, AppSpacing.md)
                        .scaleEffect(formAppear ? 1.0 : 0.95)
                        .opacity(formAppear ? 1.0 : 0.0)
                        
                        Spacer()
                            .frame(height: AppSpacing.xl)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                }
                
                // Overlays
                if isSaving || showSuccess {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }

                if isSaving {
                    LoadingOverlay()
                        .transition(.scale.combined(with: .opacity))
                }

                if showSuccess {
                    SuccessOverlay()
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationTitle(quickAction == nil ? "New Quick Action" : "Edit Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    formAppear = true
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSaving)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showSuccess)
        }
    }

    private func saveQuickAction() {
        guard isFormValid else { return }
        
        withAnimation { isSaving = true }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if let quickAction {
                quickAction.name = name
                quickAction.icon = icon
                quickAction.reason = reason
                quickAction.amount = amount
                quickAction.category = selectedCategory
            } else {
                let newQuickAction = QuickAction(
                    name: name,
                    icon: icon,
                    reason: reason,
                    amount: amount,
                    category: selectedCategory
                )
                modelContext.insert(newQuickAction)
            }
            
            withAnimation {
                isSaving = false
                showSuccess = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }
}

// MARK: - Quick Action Preview Card
struct QuickActionPreviewCard: View {
    let name: String
    let icon: String
    let amount: Double?
    let category: Category?
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Preview")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: AppSpacing.sm) {
                // Icon with gradient
                ZStack {
                    Circle()
                        .fill(Color.primaryGradient)
                        .frame(width: 60, height: 60)
                        .glowShadow(color: Color.brandMagenta)
                    
                    Text(icon)
                        .font(.system(size: 32))
                }
                
                // Name
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                // Optional details
                if let amount = amount {
                    Text(amount.toCurrency())
                        .font(.caption)
                        .foregroundColor(.brandCyan)
                        .monospacedDigit()
                }
                
                if let category = category {
                    HStack(spacing: 4) {
                        Text(category.iconName ?? "📦")
                            .font(.caption2)
                        Text(category.name)
                            .font(.caption2)
                    }
                    .foregroundColor(.textSecondary)
                }
            }
            .frame(width: 100)
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .fill(Color.cardBackground)
                    .softShadow()
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .stroke(Color.divider.opacity(0.3), lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xLarge)
                .fill(.ultraThinMaterial)
                .elevatedShadow()
        )
    }
}

#Preview {
    AddQuickActionView()
        .modelContainer(for: [QuickAction.self, Category.self], inMemory: true)
}
