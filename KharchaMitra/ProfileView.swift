import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query var settings: [UserSettings]
    @Query var categories: [Category]
    @Query var templates: [RecurringExpenseTemplate]
    @Query var quickActions: [QuickAction]
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    @State private var editableLimit: Double = 0
    @State private var isEditingLimit = false
    @State private var showSaveConfirmation = false
    @FocusState private var isLimitFieldFocused: Bool
    
    // Animation states
    @State private var headerAppear = false
    @State private var cardsAppear = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.xl) {
                    // Modern Profile Header
                    ModernProfileHeader()
                        .padding(.top, AppSpacing.md)
                        .scaleEffect(headerAppear ? 1.0 : 0.9)
                        .opacity(headerAppear ? 1.0 : 0.0)

                    // Financial Settings Card
                    ModernSettingsCard(
                        title: "Financial Settings",
                        icon: "chart.bar.fill",
                        iconColor: .successGreen
                    ) {
                        VStack(spacing: 0) {
                            HStack(spacing: AppSpacing.md) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Monthly Budget Limit")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textPrimary)
                                    
                                    Text("Set your spending target")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    TextField("", value: $editableLimit, format: .currency(code: "INR"))
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .font(.system(.title3, design: .rounded).weight(.bold))
                                        .foregroundStyle(Color.primaryGradient)
                                        .monospacedDigit()
                                        .frame(width: 120)
                                        .focused($isLimitFieldFocused)
                                        .onChange(of: editableLimit) { _, _ in
                                            isEditingLimit = true
                                        }
                                    
                                    if isEditingLimit {
                                        Button(action: saveLimit) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(Color.successGreen)
                                        }
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            }
                            .padding(AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                    .fill(Color.secondaryBackground)
                            )
                        }
                    }
                    .scaleEffect(cardsAppear ? 1.0 : 0.95)
                    .opacity(cardsAppear ? 1.0 : 0.0)

                    // App Management Card
                    ModernSettingsCard(
                        title: "App Management",
                        icon: "slider.horizontal.3",
                        iconColor: .infoBlue
                    ) {
                        VStack(spacing: 0) {
                            NavigationLink(destination: CategoriesView()) {
                                ModernSettingsRow(
                                    title: "Categories",
                                    subtitle: "Manage expense categories",
                                    icon: "list.bullet.circle.fill",
                                    iconColor: .brandMagenta,
                                    count: categories.count
                                )
                            }
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            NavigationLink(destination: RecurringPaymentsListView()) {
                                ModernSettingsRow(
                                    title: "Recurring Payments",
                                    subtitle: "Monthly bills & subscriptions",
                                    icon: "arrow.clockwise.circle.fill",
                                    iconColor: .infoBlue,
                                    count: templates.count
                                )
                            }
                            
                            Divider()
                                .padding(.leading, 60)

                            NavigationLink(destination: CustomizeQuickActionsView()) {
                                ModernSettingsRow(
                                    title: "Quick Actions",
                                    subtitle: "Customize shortcuts",
                                    icon: "bolt.circle.fill",
                                    iconColor: .warningOrange,
                                    count: quickActions.count
                                )
                            }
                            
                            Divider()
                                .padding(.leading, 60)

                            NavigationLink(destination: SettingsView()) {
                                ModernSettingsRow(
                                    title: "App Settings",
                                    subtitle: "Preferences & security",
                                    icon: "gearshape.fill",
                                    iconColor: .textSecondary,
                                    count: nil
                                )
                            }
                        }
                    }
                    .scaleEffect(cardsAppear ? 1.0 : 0.95)
                    .opacity(cardsAppear ? 1.0 : 0.0)
                    
                    // App Info Card
                    VStack(spacing: AppSpacing.xs) {
                        Text("KharchaMitra")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.textSecondary)
                        
                        Text("Version 1.0")
                            .font(.caption2)
                            .foregroundColor(.textTertiary)
                    }
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.md)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.secondaryBackground,
                        Color.tertiaryBackground.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Profile")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isLimitFieldFocused = false
                        if isEditingLimit {
                            saveLimit()
                        }
                    }
                    .foregroundStyle(Color.primaryGradient)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let limit = userSettings?.expenseLimit {
                    editableLimit = limit
                }
                
                withAnimation(.easeOut(duration: 0.5)) {
                    headerAppear = true
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                    cardsAppear = true
                }
            }
            .overlay {
                if showSaveConfirmation {
                    SaveConfirmationOverlay()
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showSaveConfirmation)
        }
    }
    
    private func saveLimit() {
        if let userSettings = userSettings {
            userSettings.expenseLimit = editableLimit
            
            withAnimation {
                isEditingLimit = false
                showSaveConfirmation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showSaveConfirmation = false
                }
            }
        }
    }
}

// MARK: - Modern Profile Header
struct ModernProfileHeader: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Profile Avatar with Gradient Ring
            ZStack {
                Circle()
                    .stroke(
                        Color.primaryGradient,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)
                    .glowShadow(color: Color.brandMagenta)
                
                ZStack {
                    Circle()
                        .fill(Color.cardBackground)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 45))
                        .foregroundStyle(Color.primaryGradient)
                }
            }
            
            VStack(spacing: 4) {
                Text("Welcome Back!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("Manage your finances")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }
}

// MARK: - Modern Settings Card
struct ModernSettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Card Header
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            
            // Card Content
            content
                .padding(.bottom, AppSpacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xLarge)
                .fill(Color.cardBackground)
                .cardShadow()
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.xLarge)
                .stroke(Color.divider.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Modern Settings Row
struct ModernSettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let count: Int?
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Count Badge & Chevron
            HStack(spacing: AppSpacing.sm) {
                if let count = count {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(minWidth: 24, minHeight: 24)
                        .background(
                            Circle()
                                .fill(iconColor.opacity(0.8))
                        )
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(AppSpacing.md)
        .contentShape(Rectangle())
    }
}

// MARK: - Save Confirmation Overlay
struct SaveConfirmationOverlay: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.successGreen.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.successGreen)
                    .symbolEffect(.bounce)
            }
            
            Text("Saved Successfully!")
                .font(.headline)
                .foregroundColor(.textPrimary)
        }
        .padding(AppSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xLarge)
                .fill(.ultraThinMaterial)
                .elevatedShadow()
        )
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserSettings.self, Category.self, RecurringExpenseTemplate.self, QuickAction.self], inMemory: true)
}
