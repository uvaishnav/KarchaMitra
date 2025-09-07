
import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var categories: [Category]

    @State private var amount: Double?
    @State private var date = Date()
    @State private var selectedCategory: Category?
    @State private var reason = ""
    @State private var isRecurring = false
    @State private var isShared = false
    @FocusState private var amountFieldIsFocused: Bool

    // Shared Expense State
    @State private var sharedParticipants: [SharedParticipant] = []
    @State private var showingAddParticipant = false
    @State private var showingContactPicker = false
    @State private var showingAddCategorySheet = false

    // State for placeholder scanning UI
    @State private var isScanning = false
    @State private var showSuccessMessage = false

    // Placeholder services
    private let receiptScanner = ReceiptScannerService()
    private let categorySuggester = CategorySuggester()

    private var isFormValid: Bool {
        amount != nil && amount ?? 0 > 0
    }
    
    init() {}

    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section {
                        Button(action: triggerScan) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Scan Receipt")
                            }
                        }
                    }

                    Section(header: Text("Expense Details")) {
                        TextField("Amount", value: $amount, format: .currency(code: "INR"))
                            .keyboardType(.decimalPad)
                            .focused($amountFieldIsFocused)

                        Picker("Category", selection: $selectedCategory) {
                            Text("None").tag(nil as Category?)
                            ForEach(categories.sorted(by: { $0.name < $1.name })) {
                                category in
                                Text(category.name).tag(category as Category?)
                            }
                        }
                        
                        Button("Create New Category") {
                            showingAddCategorySheet.toggle()
                        }
                        
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                        DatePicker("Time", selection: $date, displayedComponents: .hourAndMinute)
                    }

                    Section(header: Text("Reason (Optional)")) {
                        TextField("e.g., Lunch with the team", text: $reason)
                    }

                    Section(header: Text("Additional Options")) {
                        Toggle("Recurring Payment", isOn: $isRecurring)
                        Toggle("Shared Expense", isOn: $isShared.animation())
                    }

                    if isShared {
                        Section(header: Text("Shared With")) {
                            ForEach($sharedParticipants) { $participant in
                                HStack {
                                    Text(participant.name)
                                    Spacer()
                                    TextField("Amount", value: $participant.amountOwed, format: .currency(code: "INR"))
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                            .onDelete(perform: { indexSet in
                                sharedParticipants.remove(atOffsets: indexSet)
                            })

                            HStack {
                                Button("Add from Contacts") { showingContactPicker.toggle() }
                                    .buttonStyle(.borderless)
                                Spacer()
                                Button("Add Manually") { showingAddParticipant.toggle() }
                                    .buttonStyle(.borderless)
                            }
                            
                            if !sharedParticipants.isEmpty {
                                Button("Split Equally", action: splitEqually)
                            }
                        }
                    }
                }
                .navigationTitle("Add Expense")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Clear", action: resetForm)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save", action: saveExpense)
                            .disabled(!isFormValid)
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
                .sheet(isPresented: $showingAddParticipant) {
                    AddParticipantView(onAdd: { participant in
                        sharedParticipants.append(participant)
                    })
                }
                .sheet(isPresented: $showingContactPicker) {
                    ContactPicker { contactName in
                        let newParticipant = SharedParticipant(name: contactName, amountOwed: 0)
                        sharedParticipants.append(newParticipant)
                    }
                }
                .sheet(isPresented: $showingAddCategorySheet) {
                    AddCategoryView()
                }
                
                // Overlays for user feedback
                if isScanning || showSuccessMessage {
                    Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                }

                if isScanning {
                    ProgressView("Scanning...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }

                if showSuccessMessage {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        Text("Expense Saved!")
                            .padding(.top, 5)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
    }

    private func splitEqually() {
        guard let totalAmount = amount, !sharedParticipants.isEmpty else { return }
        let splitCount = sharedParticipants.count + 1 // Including the user
        let splitAmount = totalAmount / Double(splitCount)
        
        for i in sharedParticipants.indices {
            sharedParticipants[i].amountOwed = splitAmount
        }
    }

    private func triggerScan() {
        // In a real app, this would present the camera.
        // For now, we just use the placeholder service.
        isScanning = true
        receiptScanner.scanReceipt(image: UIImage()) { extractedData in
            isScanning = false
            
            // Pre-fill form with scanned data
            self.amount = extractedData.amount
            self.date = extractedData.date ?? Date()
            self.reason = extractedData.merchant ?? ""
            
            // Attempt to predict category
            if let merchant = extractedData.merchant {
                self.selectedCategory = categorySuggester.predictCategory(from: merchant, allCategories: categories)
            }
        }
    }

    private func saveExpense() {
        guard let amount = amount else { return }

        let newExpense = Expense(
            amount: amount,
            date: date,
            time: date, // Using the same date picker for time
            category: selectedCategory,
            reason: reason,
            isRecurring: isRecurring,
            isShared: isShared,
            sharedParticipants: sharedParticipants
        )
        modelContext.insert(newExpense)

        withAnimation {
            showSuccessMessage = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSuccessMessage = false
                resetForm()
            }
        }
    }

    private func resetForm() {
        amount = nil
        selectedCategory = nil
        reason = ""
        isRecurring = false
        isShared = false
        date = Date()
        sharedParticipants = []
    }
}

#Preview {
    AddExpenseView()
        .modelContainer(for: [Expense.self, Category.self], inMemory: true)
}
