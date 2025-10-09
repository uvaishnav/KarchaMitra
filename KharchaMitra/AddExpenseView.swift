import SwiftUI
import SwiftData
import ContactsUI

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query var categories: [Category]

    // Form State
    @State private var amount: Double?
    @State private var reason = ""
    @State private var date = Date()
    @State private var selectedCategory: Category?
    @State private var isRecurring = false
    @State private var isShared = false
    @FocusState private var focusedField: Field?

    // View State
    @State private var isSaving = false
    @State private var showSuccessMessage = false
    @State private var formAppear = false
    
    // Inline Validation State
    @State private var amountError: String?
    @State private var reasonError: String?

    // Shared Expense State
    @State private var sharedParticipants: [SharedParticipant] = []
    @State private var showingAddParticipant = false
    @State private var showingAddCategorySheet = false
    
    // Coordinator for UIKit Contact Picker
    @State private var contactPickerCoordinator: ContactPickerCoordinator?
    
    enum Field: Hashable {
        case amount
        case reason
    }

    private var isFormValid: Bool {
        amount != nil && amount ?? 0 > 0 && !reason.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(amount: Double? = nil, reason: String = "", category: Category? = nil) {
        _amount = State(initialValue: amount)
        _reason = State(initialValue: reason)
        _selectedCategory = State(initialValue: category)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
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
                        // Amount Input Section (Hero)
                        AmountInputCard(
                            amount: $amount,
                            amountError: $amountError,
                            focusedField: $focusedField
                        )
                        .scaleEffect(formAppear ? 1.0 : 0.95)
                        .opacity(formAppear ? 1.0 : 0.0)
                        
                        // Basic Details Section
                        ModernFormCard(title: "Details", icon: "info.circle.fill") {
                            VStack(spacing: AppSpacing.md) {
                                // Reason Input
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Label("Reason", systemImage: "text.alignleft")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textSecondary)
                                    
                                    TextField("What did you spend on?", text: $reason)
                                        .font(.body)
                                        .padding(AppSpacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                                .fill(Color.secondaryBackground)
                                        )
                                        .focused($focusedField, equals: .reason)
                                        .onChange(of: reason) { _, _ in validateReason() }
                                    
                                    if let reasonError {
                                        HStack(spacing: 4) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .font(.caption2)
                                            Text(reasonError)
                                                .font(.caption)
                                        }
                                        .foregroundColor(.errorRed)
                                        .transition(.opacity)
                                    }
                                }
                                
                                // Category Picker
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Label("Category", systemImage: "tag.fill")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textSecondary)
                                    
                                    HStack(spacing: AppSpacing.sm) {
                                        Picker(selection: $selectedCategory) {
                                            Text("Select Category").tag(nil as Category?)
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
                                                    Text("Select Category")
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
                                        
                                        Button(action: { showingAddCategorySheet.toggle() }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(Color.primaryGradient)
                                        }
                                    }
                                }
                                
                                // Date Picker
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Label("Date", systemImage: "calendar")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textSecondary)
                                    
                                    DatePicker("", selection: $date, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .tint(Color.brandMagenta)
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
                        
                        // Options Section
                        ModernFormCard(title: "Options", icon: "slider.horizontal.3") {
                            VStack(spacing: AppSpacing.md) {
                                ModernToggle(
                                    isOn: $isRecurring,
                                    title: "Recurring Payment",
                                    subtitle: "Save as monthly template",
                                    icon: "arrow.clockwise.circle.fill",
                                    iconColor: .infoBlue
                                )
                                
                                ModernToggle(
                                    isOn: $isShared,
                                    title: "Shared Expense",
                                    subtitle: "Split with others",
                                    icon: "person.2.circle.fill",
                                    iconColor: .warningOrange
                                )
                            }
                        }
                        .scaleEffect(formAppear ? 1.0 : 0.95)
                        .opacity(formAppear ? 1.0 : 0.0)
                        
                        // Shared Participants Section
                        if isShared {
                            SharedParticipantsCard(
                                participants: $sharedParticipants,
                                showingAddParticipant: $showingAddParticipant,
                                amount: amount,
                                onSplitEqually: splitEqually,
                                onPresentContactPicker: presentContactPicker
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                        }
                        
                        // Save Button
                        Button(action: saveExpense) {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text("Save Expense")
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
                if isSaving || showSuccessMessage {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }

                if isSaving {
                    LoadingOverlay()
                        .transition(.scale.combined(with: .opacity))
                }

                if showSuccessMessage {
                    SuccessOverlay()
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .foregroundStyle(Color.primaryGradient)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAddParticipant) {
                AddParticipantView(onAdd: { p in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        sharedParticipants.append(p)
                    }
                })
            }
            .sheet(isPresented: $showingAddCategorySheet) {
                AddCategoryView(onCategoryAdded: { c in
                    self.selectedCategory = c
                })
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    formAppear = true
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isShared)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSaving)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showSuccessMessage)
        }
    }

    private func presentContactPicker() {
        let coordinator = ContactPickerCoordinator(
            onSelect: { name in
                withAnimation {
                    self.sharedParticipants.append(.init(name: name, amountOwed: 0))
                }
                self.contactPickerCoordinator = nil
            },
            onCancel: {
                self.contactPickerCoordinator = nil
            }
        )
        self.contactPickerCoordinator = coordinator

        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = coordinator
        contactPicker.displayedPropertyKeys = [CNContactGivenNameKey, CNContactFamilyNameKey]

        var topViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene }).first?.windows.first?.rootViewController
        
        while let presentedViewController = topViewController?.presentedViewController {
            topViewController = presentedViewController
        }

        guard let topVC = topViewController else {
            self.contactPickerCoordinator = nil
            return
        }

        topVC.present(contactPicker, animated: true)
    }

    private func validateAmount() {
        if amount == nil || amount ?? 0 <= 0 {
            amountError = "Amount must be greater than zero"
        } else {
            amountError = nil
        }
    }
    
    private func validateReason() {
        if reason.trimmingCharacters(in: .whitespaces).isEmpty {
            reasonError = "Please enter a reason"
        } else {
            reasonError = nil
        }
    }

    private func splitEqually() {
        guard let totalAmount = amount, !sharedParticipants.isEmpty else { return }
        let splitCount = sharedParticipants.count + 1
        let splitAmount = totalAmount / Double(splitCount)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            for i in sharedParticipants.indices {
                sharedParticipants[i].amountOwed = splitAmount
            }
        }
    }

    private func saveExpense() {
        validateAmount()
        validateReason()
        guard isFormValid else { return }
        
        withAnimation { isSaving = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard let amount = amount else {
                isSaving = false
                return
            }

            let newExpense = Expense(
                amount: amount,
                date: date,
                time: date,
                category: selectedCategory,
                reason: reason,
                isRecurring: isRecurring,
                isShared: isShared,
                sharedParticipants: sharedParticipants
            )
            modelContext.insert(newExpense)

            if isRecurring {
                let newTemplate = RecurringExpenseTemplate(
                    amount: amount,
                    category: selectedCategory,
                    reason: reason
                )
                modelContext.insert(newTemplate)
            }

            withAnimation {
                isSaving = false
                showSuccessMessage = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                dismiss()
            }
        }
    }
}

// MARK: - Amount Input Card
struct AmountInputCard: View {
    @Binding var amount: Double?
    @Binding var amountError: String?
    var focusedField: FocusState<AddExpenseView.Field?>.Binding
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Currency Symbol and Label
            HStack {
                Label("Enter Amount", systemImage: "indianrupeesign.circle.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                Spacer()
            }
            
            // Large Amount Input
            HStack(spacing: 8) {
                Text("₹")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primaryGradient)
                
                TextField("0", value: $amount, format: .number.precision(.fractionLength(2)))
                    .keyboardType(.decimalPad)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primaryGradient)
                    .monospacedDigit()
                    .focused(focusedField, equals: .amount)
                    .onChange(of: amount) { _, newValue in
                        if newValue != nil && (newValue ?? 0) > 0 {
                            amountError = nil
                        }
                    }
            }
            .padding(.vertical, AppSpacing.sm)
            
            if let amountError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(amountError)
                        .font(.caption)
                }
                .foregroundColor(.errorRed)
                .transition(.opacity)
            }
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xLarge)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.xLarge)
                        .stroke(
                            (amount != nil && (amount ?? 0) > 0 ?
                            AnyShapeStyle(Color.primaryGradient.opacity(0.5)) :
                            AnyShapeStyle(Color.divider.opacity(0.3))),
                            lineWidth: 2
                        )
                )
                .elevatedShadow()
        )
    }
}

// MARK: - Modern Form Card
struct ModernFormCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label(title, systemImage: icon)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            content
        }
        .padding(AppSpacing.md)
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

// MARK: - Modern Toggle
struct ModernToggle: View {
    @Binding var isOn: Bool
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        Toggle(isOn: $isOn.animation(.spring(response: 0.4, dampingFraction: 0.7))) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .tint(Color.brandMagenta)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(Color.secondaryBackground)
        )
    }
}

// MARK: - Shared Participants Card
struct SharedParticipantsCard: View {
    @Binding var participants: [SharedParticipant]
    @Binding var showingAddParticipant: Bool
    let amount: Double?
    let onSplitEqually: () -> Void
    let onPresentContactPicker: () -> Void
    
    var body: some View {
        ModernFormCard(title: "Split With", icon: "person.2.fill") {
            VStack(spacing: AppSpacing.md) {
                // Participant List
                ForEach($participants) { $participant in
                    HStack(spacing: AppSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.primaryGradient.opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.primaryGradient)
                        }
                        
                        Text(participant.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        TextField("", value: $participant.amountOwed, format: .currency(code: "INR"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(.brandCyan)
                            .monospacedDigit()
                            .frame(width: 100)
                    }
                    .padding(AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .fill(Color.secondaryBackground)
                    )
                }
                .onDelete { indexSet in
                    withAnimation {
                        participants.remove(atOffsets: indexSet)
                    }
                }
                
                // Add Participant Buttons
                HStack(spacing: AppSpacing.sm) {
                    Button(action: onPresentContactPicker) {
                        Label("Contacts", systemImage: "person.crop.circle.badge.plus")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.brandCyan)
                    
                    Button(action: { showingAddParticipant.toggle() }) {
                        Label("Manual", systemImage: "plus.circle")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.brandMagenta)
                }
                
                // Split Equally Button
                if !participants.isEmpty && amount != nil {
                    Button(action: onSplitEqually) {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "equal.circle.fill")
                            Text("Split Equally")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .fill(Color.warningOrange)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Saving...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(AppSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xLarge)
                .fill(.ultraThinMaterial)
                .elevatedShadow()
        )
    }
}

// MARK: - Success Overlay
struct SuccessOverlay: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.successGreen.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.successGreen)
                    .symbolEffect(.bounce)
            }
            
            VStack(spacing: AppSpacing.xs) {
                Text("Expense Saved!")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Text("Your transaction has been recorded")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(AppSpacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xLarge)
                .fill(.ultraThinMaterial)
                .elevatedShadow()
        )
    }
}

// MARK: - Contact Picker Coordinator
fileprivate class ContactPickerCoordinator: NSObject, CNContactPickerDelegate {
    var onSelect: (String) -> Void
    var onCancel: () -> Void

    init(onSelect: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.onSelect = onSelect
        self.onCancel = onCancel
        super.init()
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let fullName = CNContactFormatter.string(from: contact, style: .fullName) ?? "Unknown Contact"
        picker.dismiss(animated: true) {
            self.onSelect(fullName)
        }
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        picker.dismiss(animated: true) {
            self.onCancel()
        }
    }
}

#Preview {
    AddExpenseView()
        .modelContainer(for: [Expense.self, Category.self], inMemory: true)
}
