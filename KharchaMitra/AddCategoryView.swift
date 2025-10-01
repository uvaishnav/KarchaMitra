import SwiftUI

struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var icon: String = ""
    @State private var type: CategoryType = .need
    @State private var selectedColor: String = "#E91E63"
    @State private var showColorPicker = false
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var formAppear = false

    var onCategoryAdded: ((Category) -> Void)?
    
    private let suggestedIcons = ["🛒", "🍔", "🚗", "🏠", "💡", "📱", "👕", "🎮", "✈️", "💊", "🎬", "📚", "☕", "🎵", "💰"]
    
    private let colorPalette = [
        "#E91E63", "#9C27B0", "#673AB7", "#3F51B5", "#2196F3",
        "#00BCD4", "#009688", "#4CAF50", "#8BC34A", "#CDDC39",
        "#FFC107", "#FF9800", "#FF5722", "#795548", "#607D8B"
    ]

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !icon.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    init(onCategoryAdded: ((Category) -> Void)? = nil) {
        self.onCategoryAdded = onCategoryAdded
    }

    var body: some View {
        NavigationView {
            ZStack {
                background
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.lg) {
                        previewCard
                        basicInfoSection
                        iconSection
                        colorSection
                        saveButton
                        
                        Spacer().frame(height: AppSpacing.xl)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                }
                
                overlays
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { 
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    formAppear = true
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: type)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSaving)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showSuccess)
        }
    }

    private func saveCategory() {
        guard isFormValid else { return }
        
        withAnimation { isSaving = true }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let newCategory = Category(name: name, type: type, iconName: icon, colorHex: selectedColor)
            modelContext.insert(newCategory)
            onCategoryAdded?(newCategory)
            
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

// MARK: - Subviews
private extension AddCategoryView {
    var background: some View {
        LinearGradient(
            colors: [
                Color.secondaryBackground,
                Color.tertiaryBackground.opacity(0.5)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    var overlays: some View {
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
    
    var previewCard: some View {
        CategoryPreviewCard(
            name: name.isEmpty ? "Category Name" : name,
            icon: icon.isEmpty ? "❓" : icon,
            color: selectedColor,
            type: type
        )
        .scaleEffect(formAppear ? 1.0 : 0.9)
        .opacity(formAppear ? 1.0 : 0.0)
    }
    
    var basicInfoSection: some View {
        ModernFormCard(title: "Basic Info", icon: "info.circle.fill") {
            VStack(spacing: AppSpacing.md) {
                // Name Input
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Label("Category Name", systemImage: "tag.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.textSecondary)
                    
                    TextField("e.g., Groceries, Transport", text: $name)
                        .font(.body)
                        .padding(AppSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .fill(Color.secondaryBackground)
                        )
                }
                
                // Type Picker
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Label("Category Type", systemImage: "slider.horizontal.3")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.textSecondary)
                    
                    Picker("Type", selection: $type) {
                        HStack { Image(systemName: "exclamationmark.circle.fill"); Text("Need") }.tag(CategoryType.need)
                        HStack { Image(systemName: "heart.circle.fill"); Text("Want") }.tag(CategoryType.want)
                        HStack { Image(systemName: "briefcase.circle.fill"); Text("UTR") }.tag(CategoryType.UTR)
                    }
                    .pickerStyle(.segmented)
                    .background(Color.secondaryBackground)
                    .cornerRadius(AppCornerRadius.small)
                }
                
                // Info about UTR
                if type == .UTR {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "info.circle.fill").foregroundColor(.infoBlue)
                        Text("UTR expenses don't affect your personal spending limit")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.small)
                            .fill(Color.infoBlue.opacity(0.1))
                    )
                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                }
            }
        }
        .scaleEffect(formAppear ? 1.0 : 0.95)
        .opacity(formAppear ? 1.0 : 0.0)
    }
    
    var iconSection: some View {
        ModernFormCard(title: "Choose Icon", icon: "face.smiling.fill") {
            VStack(spacing: AppSpacing.md) {
                // Selected Icon Display
                if !icon.isEmpty {
                    Text(icon)
                        .font(.system(size: 60))
                        .frame(maxWidth: .infinity)
                        .padding(AppSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                                .fill(Color(hex: selectedColor).opacity(0.15))
                        )
                }
                
                // Suggested Icons Grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: AppSpacing.sm) {
                    ForEach(suggestedIcons, id: \.self) { emoji in
                        Button(action: { icon = emoji }) {
                            Text(emoji)
                                .font(.system(size: 32))
                                .frame(width: 50, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                        .fill(icon == emoji ? Color(hex: selectedColor).opacity(0.2) : Color.secondaryBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                        .stroke(icon == emoji ? Color(hex: selectedColor) : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                
                // Custom Emoji Input
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Or enter custom emoji").font(.caption).foregroundColor(.textSecondary)
                    EmojiTextField(text: $icon, placeholder: "Tap to enter emoji")
                        .font(.title)
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
    }
    
    var colorSection: some View {
        ModernFormCard(title: "Pick Color", icon: "paintpalette.fill") {
            VStack(spacing: AppSpacing.md) {
                // Selected Color Display
                HStack(spacing: AppSpacing.md) {
                    Circle()
                        .fill(Color(hex: selectedColor))
                        .frame(width: 50, height: 50)
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        .shadow(color: Color(hex: selectedColor).opacity(0.5), radius: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Selected Color").font(.caption).foregroundColor(.textSecondary)
                        Text(selectedColor.uppercased())
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                        .fill(Color.secondaryBackground)
                )
                
                // Color Grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: AppSpacing.sm) {
                    ForEach(colorPalette, id: \.self) { hexColor in
                        Button(action: { selectedColor = hexColor }) {
                            ZStack {
                                Circle().fill(Color(hex: hexColor)).frame(width: 44, height: 44)
                                if selectedColor == hexColor {
                                    Image(systemName: "checkmark.circle.fill").font(.title3).foregroundColor(.white).shadow(radius: 2)
                                }
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
        }
        .scaleEffect(formAppear ? 1.0 : 0.95)
        .opacity(formAppear ? 1.0 : 0.0)
    }
    
    var saveButton: some View {
        Button(action: saveCategory) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "checkmark.circle.fill").font(.title3)
                Text("Create Category").font(.headline)
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
    }
}

// MARK: - Category Preview Card
struct CategoryPreviewCard: View {
    let name: String
    let icon: String
    let color: String
    let type: CategoryType
    
    var typeIcon: String {
        switch type {
        case .need: return "exclamationmark.circle.fill"
        case .want: return "heart.circle.fill"
        case .UTR: return "briefcase.circle.fill"
        }
    }
    
    var typeColor: Color {
        switch type {
        case .need: return .errorRed
        case .want: return .successGreen
        case .UTR: return .infoBlue
        }
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Preview")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: AppSpacing.md) {
                // Icon with color background
                ZStack {
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                        .fill(Color(hex: color).opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Text(icon)
                        .font(.system(size: 32))
                }
                
                // Category Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: typeIcon)
                            .font(.caption)
                        Text(type.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(typeColor)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(typeColor.opacity(0.15))
                    )
                }
                
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .fill(Color.cardBackground)
                    .softShadow()
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .stroke(Color(hex: color).opacity(0.3), lineWidth: 2)
            )
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
    AddCategoryView()
}
