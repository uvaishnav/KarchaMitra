import SwiftUI
import SwiftData

// A wrapper to unify Expenses and Settlements into a single list
enum HistoryItem: Identifiable, Hashable {
    case expense(Expense)
    case settlement(Settlement)

    var id: AnyHashable {
        switch self {
        case .expense(let e):
            return e.id
        case .settlement(let s):
            return s.id
        }
    }

    var date: Date {
        switch self {
        case .expense(let e):
            return e.date
        case .settlement(let s):
            return s.date
        }
    }
}

struct HistoryView: View {
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    @Query(sort: \Settlement.date, order: .reverse) var settlements: [Settlement]

    // Filter State
    enum FilterType: String, CaseIterable {
        case all = "All"
        case month = "By Month"
        case year = "By Year"
        case dateRange = "Date Range"
    }
    @State private var filterType: FilterType = .all
    @State private var selectedDate = Date()
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var showingFilters = true // Show by default

    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    // State for the CSV export
    @State private var isShareSheetPresented = false
    @State private var csvURL: URL? = nil

    private var combinedItems: [HistoryItem] {
        let expenseItems = expenses.map { HistoryItem.expense($0) }
        let settlementItems = settlements.map { HistoryItem.settlement($0) }
        return (expenseItems + settlementItems).sorted { $0.date > $1.date }
    }

    private var filteredItems: [HistoryItem] {
        switch filterType {
        case .all:
            return combinedItems
        case .month:
            return combinedItems.filter {
                let monthMatch = Calendar.current.isDate($0.date, equalTo: selectedDate, toGranularity: .month)
                let yearMatch = Calendar.current.isDate($0.date, equalTo: selectedDate, toGranularity: .year)
                return monthMatch && yearMatch
            }
        case .year:
            return combinedItems.filter {
                Calendar.current.component(.year, from: $0.date) == selectedYear
            }
        case .dateRange:
            // Adjust endDate to be the end of the selected day
            let adjustedEndDate = Calendar.current.startOfDay(for: endDate).addingTimeInterval(24*60*60-1)
            return combinedItems.filter {
                $0.date >= Calendar.current.startOfDay(for: startDate) && $0.date <= adjustedEndDate
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Filter UI
                DisclosureGroup("Filters", isExpanded: $showingFilters) {
                    VStack {
                        Picker("Filter By", selection: $filterType.animation()) {
                            ForEach(FilterType.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)

                        if filterType == .month {
                            HStack {
                                Picker("Month", selection: $selectedMonth) {
                                    ForEach(1...12, id: \.self) {
                                        Text(Calendar.current.monthSymbols[$0 - 1]).tag($0)
                                    }
                                }
                                .pickerStyle(.menu)

                                Picker("Year", selection: $selectedYear) {
                                    ForEach(((Calendar.current.component(.year, from: Date()) - 10)...(Calendar.current.component(.year, from: Date()))).reversed(), id: \.self) {
                                        Text(String($0)).tag($0)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .onChange(of: selectedMonth) { updateSelectedDateFromComponents() }
                            .onChange(of: selectedYear) { updateSelectedDateFromComponents() }
                        } else if filterType == .year {
                            Picker("Select Year", selection: $selectedYear) {
                                ForEach(((Calendar.current.component(.year, from: Date()) - 10)...(Calendar.current.component(.year, from: Date()))).reversed(), id: \.self) {
                                    Text(String($0)).tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedYear) { updateSelectedDateFromComponents() }
                        }

                        if filterType == .dateRange {
                            VStack {
                                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                            }
                        }
                    }
                    .padding(.top)
                }
                .padding(.horizontal)

                // Transaction List
                List {
                    ForEach(filteredItems) { item in
                        switch item {
                        case .expense(let expense):
                            expenseRow(expense: expense)
                        case .settlement(let settlement):
                            settlementRow(settlement: settlement)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export", systemImage: "square.and.arrow.up", action: generateAndShareCSV)
                }
            }
            .sheet(isPresented: $isShareSheetPresented) {
                if let csvURL = csvURL {
                    ShareSheet(activityItems: [csvURL])
                }
            }
            .onAppear(perform: setupInitialDate)
        }
    }

    private func setupInitialDate() {
        selectedMonth = Calendar.current.component(.month, from: selectedDate)
        selectedYear = Calendar.current.component(.year, from: selectedDate)
    }

    private func updateSelectedDateFromComponents() {
        let components = DateComponents(year: selectedYear, month: selectedMonth)
        selectedDate = Calendar.current.date(from: components) ?? Date()
    }

    @ViewBuilder
    private func expenseRow(expense: Expense) -> some View {
        HStack {
            Image(systemName: "arrow.down.circle.fill")
                .font(.title)
                .foregroundColor(.red)
            
            VStack(alignment: .leading) {
                Text(expense.reason ?? expense.category?.name ?? "Uncategorized")
                    .font(.headline)
                Text(expense.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("-\(expense.amount.toCurrency())")
                .font(.headline)
                .foregroundColor(.red)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func settlementRow(settlement: Settlement) -> some View {
        DisclosureGroup {
            // Expanded content: List of related expenses
            VStack(alignment: .leading, spacing: 8) {
                Text("Related Shared Expenses with \(settlement.participantName):")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)

                let relatedExpenses = expenses.filter {
                    $0.isShared && $0.sharedParticipants.contains { $0.name == settlement.participantName }
                }

                if relatedExpenses.isEmpty {
                    Text("No specific shared expenses found.")
                        .font(.caption)
                } else {
                    ForEach(relatedExpenses) { expense in
                        HStack {
                            Text("\(expense.reason ?? expense.category?.name ?? "Uncategorized")")
                            Spacer()
                            Text(expense.amount.toCurrency())
                        }
                        .font(.caption)
                        .padding(.leading)
                    }
                }
            }
        } label: {
            // The main, visible row
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading) {
                    Text("Payment from \(settlement.participantName)")
                        .font(.headline)
                    Text(settlement.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("+\(settlement.amount.toCurrency())")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            .padding(.vertical, 4)
        }
    }
    
    private func generateAndShareCSV() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "KharchaMitra_Export_\(dateFormatter.string(from: Date())).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var csvText = "Date,Type,Amount,Category,Reason,Participant\n"
        
        for item in filteredItems {
            let date = dateFormatter.string(from: item.date)
            
            switch item {
            case .expense(let expense):
                let amount = "-\(expense.amount)"
                let category = expense.category?.name ?? "N/A"
                let reason = expense.reason?.replacingOccurrences(of: ",", with: "") ?? ""
                csvText.append("\(date),Expense,\(amount)," + category + "," + reason + "\n")
            case .settlement(let settlement):
                let amount = "+\(settlement.amount)"
                let participant = settlement.participantName
                csvText.append("\(date),Settlement,\(amount),N/A,Payment from \(participant),\(participant)\n")
            }
        }
        
        do {
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
            self.csvURL = fileURL
            self.isShareSheetPresented = true
        } catch {
            print("Failed to create CSV file: \(error.localizedDescription)")
        }
    }
}




#Preview {
    HistoryView()
        .modelContainer(for: [Expense.self, Settlement.self, Category.self], inMemory: true)
}
