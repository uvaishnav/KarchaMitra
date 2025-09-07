import SwiftUI
import SwiftData

// A wrapper to unify Expenses and Settlements into a single list
enum HistoryItem: Identifiable, Hashable {
    case expense(Expense)
    case settlement(Settlement)

    var id: UUID {
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
                Calendar.current.isDate($0.date, equalTo: selectedDate, toGranularity: .month) &&
                Calendar.current.isDate($0.date, equalTo: selectedDate, toGranularity: .year)
            }
        case .year:
            return combinedItems.filter {
                Calendar.current.isDate($0.date, equalTo: selectedDate, toGranularity: .year)
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
                            ForEach(FilterType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)

                        if filterType == .month || filterType == .year {
                            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
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
        }
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
}

#Preview {
    HistoryView()
        .modelContainer(for: [Expense.self, Settlement.self, Category.self], inMemory: true)
}