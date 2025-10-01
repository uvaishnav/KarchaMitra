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
    @FocusState private var isKeyboardFocused: Bool

    // View State
    @State private var isSaving = false
    @State private var showSuccessMessage = false
    
    // Inline Validation State
    @State private var amountError: String?
    @State private var reasonError: String?

    // Shared Expense State
    @State private var sharedParticipants: [SharedParticipant] = []
    @State private var showingAddParticipant = false
    @State private var showingAddCategorySheet = false
    
    // Coordinator for UIKit Contact Picker
    @State private var contactPickerCoordinator: ContactPickerCoordinator?

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
                Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 16) {
                            TextField("Amount", value: $amount, format: .currency(code: "INR"))
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .focused($isKeyboardFocused)
                                .onChange(of: amount) { _, _ in validateAmount() }

                            if let amountError {
                                Text(amountError).font(.caption).foregroundColor(.red)
                            }

                            TextField("Reason for expense", text: $reason)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .focused($isKeyboardFocused)
                                .onChange(of: reason) { _, _ in validateReason() }
                            
                            if let reasonError {
                                Text(reasonError).font(.caption).foregroundColor(.red)
                            }
                            
                            HStack {
                                Picker("Category", selection: $selectedCategory) {
                                    Text("Select Category").tag(nil as Category?)
                                    ForEach(categories.sorted(by: { $0.name < $1.name })) { category in
                                        Text(category.name).tag(category as Category?)
                                    }
                                }
                                .pickerStyle(.menu)
                                Spacer()
                                Button("New") { showingAddCategorySheet.toggle() }
                                    .buttonStyle(.bordered)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(12)
                            
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            Toggle(isOn: $isRecurring) {
                                HStack {
                                    Image(systemName: "arrow.2.squarepath")
                                    Text("Make this a recurring payment")
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .tint(.accentColor)
                            
                            Toggle(isOn: $isShared.animation()) {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                    Text("Share this expense")
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .tint(.accentColor)
                        }
                        .padding(.horizontal, 24)
                        
                        if isShared {
                            VStack(spacing: 12) {
                                ForEach($sharedParticipants) { $participant in
                                    HStack {
                                        Text(participant.name)
                                        Spacer()
                                        TextField("Amount", value: $participant.amountOwed, format: .currency(code: "INR"))
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 100)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                }
                                .onDelete(perform: { indexSet in
                                    sharedParticipants.remove(atOffsets: indexSet)
                                })
                                
                                HStack(spacing: 12) {
                                    Button { self.presentContactPicker() } label: {
                                        Label("From Contacts", systemImage: "person.crop.circle.badge.plus")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button { showingAddParticipant.toggle() } label: {
                                        Label("Manually", systemImage: "plus.circle")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                }
                                
                                if !sharedParticipants.isEmpty {
                                    Button("Split Equally", action: splitEqually)
                                        .frame(maxWidth: .infinity)
                                        .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding(.horizontal, 24)
                            .transition(.asymmetric(insertion: .scale, removal: .opacity))
                        }
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Add Expense")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save", action: saveExpense)
                            .disabled(!isFormValid)
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { isKeyboardFocused = false }
                    }
                }
                .sheet(isPresented: $showingAddParticipant) { AddParticipantView(onAdd: { p in sharedParticipants.append(p) }) }
                .sheet(isPresented: $showingAddCategorySheet) { AddCategoryView(onCategoryAdded: { c in self.selectedCategory = c }) }
                
                if isSaving || showSuccessMessage {
                    Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                }

                if isSaving {
                    ProgressView().scaleEffect(2).progressViewStyle(CircularProgressViewStyle(tint: .white))
                }

                if showSuccessMessage {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                            .symbolEffect(.bounce, value: showSuccessMessage)
                        Text("Expense Saved!").padding(.top, 5)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
    }

    private func presentContactPicker() {
        let coordinator = ContactPickerCoordinator(
            onSelect: { name in
                self.sharedParticipants.append(.init(name: name, amountOwed: 0))
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
            amountError = "Amount must be greater than zero."
        } else {
            amountError = nil
        }
    }
    
    private func validateReason() {
        if reason.trimmingCharacters(in: .whitespaces).isEmpty {
            reasonError = "Reason cannot be empty."
        } else {
            reasonError = nil
        }
    }

    private func splitEqually() {
        guard let totalAmount = amount, !sharedParticipants.isEmpty else { return }
        let splitCount = sharedParticipants.count + 1
        let splitAmount = totalAmount / Double(splitCount)
        
        for i in sharedParticipants.indices {
            sharedParticipants[i].amountOwed = splitAmount
        }
    }

    private func saveExpense() {
        validateAmount()
        validateReason()
        guard isFormValid else { return }
        
        withAnimation { isSaving = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let amount = amount else {
                isSaving = false
                return
            }

            let newExpense = Expense(amount: amount, date: date, time: date, category: selectedCategory, reason: reason, isRecurring: isRecurring, isShared: isShared, sharedParticipants: sharedParticipants)
            modelContext.insert(newExpense)

            if isRecurring {
                let newTemplate = RecurringExpenseTemplate(amount: amount, category: selectedCategory, reason: reason)
                modelContext.insert(newTemplate)
            }

            withAnimation {
                isSaving = false
                showSuccessMessage = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }
}

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