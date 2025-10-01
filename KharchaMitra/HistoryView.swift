import SwiftUI
import SwiftData

// A wrapper to unify Expenses and Settlements into a single list
enum HistoryItem: Identifiable, Hashable {
    case expense(Expense)
    case settlement(Settlement)

    var id: AnyHashable {
        switch self {
        case .expense(let e): return e.id
        case .settlement(let s): return s.id
        }
    }

    var date: Date {
        switch self {
        case .expense(let e): return e.date
        case .settlement(let s): return s.date
        }
    }
}

struct HistoryView: View {
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    @Query(sort: \Settlement.date, order: .reverse) var settlements: [Settlement]

    // Filter State
    enum FilterType: String, CaseIterable, Identifiable {
        case all = "All"
        case thisMonth = "This Month"
        case thisYear = "This Year"
        case dateRange = "Date Range"
        var id: String { self.rawValue }
    }
    @State private var filterType: FilterType = .thisMonth
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var showDateRangePicker = false

    // CSV Export State
    @State private var isShareSheetPresented = false
    @State private var csvURL: URL?

    private var combinedItems: [HistoryItem] {
        (expenses.map(HistoryItem.expense) + settlements.map(HistoryItem.settlement)).sorted { $0.date > $1.date }
    }

    private var filteredItems: [HistoryItem] {
        let now = Date()
        let calendar = Calendar.current
        
        switch filterType {
        case .all:
            return combinedItems
        case .thisMonth:
            return combinedItems.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .thisYear:
            return combinedItems.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .year) }
        case .dateRange:
            let adjustedEndDate = calendar.startOfDay(for: endDate).addingTimeInterval(24*60*60-1)
            return combinedItems.filter { $0.date >= calendar.startOfDay(for: startDate) && $0.date <= adjustedEndDate }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                FilterChipView(selectedFilter: $filterType, showDateRangePicker: $showDateRangePicker)
                    .padding(.vertical)

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
                .listStyle(.plain)
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export", systemImage: "square.and.arrow.up", action: generateAndShareCSV)
                }
            }
            .sheet(isPresented: $showDateRangePicker) {
                dateRangePickerSheet
            }
            .sheet(isPresented: $isShareSheetPresented) {
                if let csvURL { ShareSheet(activityItems: [csvURL]) }
            }
        }
    }
    
    var dateRangePickerSheet: some View {
        NavigationView {
            Form {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }
            .navigationTitle("Select Date Range")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showDateRangePicker = false }
                }
            }
        }
    }

    @ViewBuilder
    private func expenseRow(expense: Expense) -> some View {
        HStack(spacing: 15) {
            Capsule()
                .fill(Color(hex: expense.category?.colorHex ?? "#000000"))
                .frame(width: 4)
            
            Image(systemName: "arrow.down.circle.fill")
                .font(.title)
                .foregroundColor(.red)
            
            VStack(alignment: .leading) {
                Text(expense.reason ?? expense.category?.name ?? "Uncategorized").font(.headline)
                Text(expense.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("-\(expense.amount.toCurrency())").font(.headline).foregroundColor(.red)
        }
        .padding(.vertical, 4)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private func settlementRow(settlement: Settlement) -> some View {
        HStack(spacing: 15) {
            Capsule().fill(.green).frame(width: 4)
            
            Image(systemName: "arrow.up.circle.fill").font(.title).foregroundColor(.green)
            
            VStack(alignment: .leading) {
                Text("Payment from \(settlement.participantName)").font(.headline)
                Text(settlement.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("+\(settlement.amount.toCurrency())").font(.headline).foregroundColor(.green)
        }
        .padding(.vertical, 4)
        .listRowSeparator(.hidden)
    }
    
    private func generateAndShareCSV() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        var csvString = "Date,Type,Amount,Reason,Category\n"

        for item in filteredItems {
            switch item {
            case .expense(let expense):
                let date = formatter.string(from: expense.date)
                let type = "Expense"
                let amount = -expense.amount
                let reason = expense.reason?.replacingOccurrences(of: ",", with: "") ?? ""
                let category = expense.category?.name ?? "Uncategorized"
                csvString.append("\(date),\(type),\(amount),\(reason),\(category)\n")
            case .settlement(let settlement):
                let date = formatter.string(from: settlement.date)
                let type = "Settlement"
                let amount = settlement.amount
                let reason = "Payment from \(settlement.participantName)".replacingOccurrences(of: ",", with: "")
                let category = "Income"
                csvString.append("\(date),\(type),\(amount),\(reason),\(category)\n")
            }
        }

        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let fileName = "KharchaMitra_Export_\(Date().timeIntervalSince1970).csv"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            
            self.csvURL = fileURL
            self.isShareSheetPresented = true
            
        } catch {
            print("Failed to generate CSV: \(error.localizedDescription)")
        }
    }
}

struct FilterChipView: View {
    @Binding var selectedFilter: HistoryView.FilterType
    @Binding var showDateRangePicker: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(HistoryView.FilterType.allCases) { filter in
                    Button(action: {
                        if filter == .dateRange {
                            showDateRangePicker = true
                        }
                        selectedFilter = filter
                    }) {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(selectedFilter == filter ? .blue : .clear)
                            .foregroundColor(selectedFilter == filter ? .white : .blue)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue, lineWidth: 1.5)
                            )
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}


#Preview {
    HistoryView()
        .modelContainer(for: [Expense.self, Settlement.self, Category.self], inMemory: true)
}