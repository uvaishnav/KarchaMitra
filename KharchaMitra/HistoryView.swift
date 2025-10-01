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
    @State private var isExporting = false
    
    // Animation State
    @State private var listAppear = false

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
    
    private var totalExpenses: Double {
        filteredItems.compactMap { item in
            if case .expense(let expense) = item {
                return expense.amount
            }
            return nil
        }.reduce(0, +)
    }
    
    private var totalSettlements: Double {
        filteredItems.compactMap { item in
            if case .settlement(let settlement) = item {
                return settlement.amount
            }
            return nil
        }.reduce(0, +)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Summary Stats Header
                HistorySummaryHeader(
                    totalExpenses: totalExpenses,
                    totalSettlements: totalSettlements,
                    itemCount: filteredItems.count
                )
                .padding(.top, AppSpacing.sm)
                
                // Modern Filter Chips
                ModernFilterChipView(
                    selectedFilter: $filterType,
                    showDateRangePicker: $showDateRangePicker
                )
                .padding(.vertical, AppSpacing.md)

                // Transaction List
                if filteredItems.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: AppSpacing.sm) {
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                switch item {
                                case .expense(let expense):
                                    ModernExpenseRow(expense: expense)
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)
                                        ))
                                case .settlement(let settlement):
                                    ModernSettlementRow(settlement: settlement)
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)
                                        ))
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.xl)
                    }
                }
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
            .navigationTitle("Transaction History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: generateAndShareCSV) {
                        HStack(spacing: 4) {
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .foregroundStyle(Color.primaryGradient)
                    }
                    .disabled(isExporting || filteredItems.isEmpty)
                }
            }
            .sheet(isPresented: $showDateRangePicker) {
                dateRangePickerSheet
            }
            .sheet(isPresented: $isShareSheetPresented) {
                if let csvURL { ShareSheet(activityItems: [csvURL]) }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: filteredItems.count)
        }
    }
    
    var dateRangePickerSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Modern Date Pickers
                VStack(spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Label("Start Date", systemImage: "calendar")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.textSecondary)
                        
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(Color.brandMagenta)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Label("End Date", systemImage: "calendar")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.textSecondary)
                        
                        DatePicker("", selection: $endDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(Color.brandCyan)
                    }
                }
                .padding(AppSpacing.lg)
            }
            .background(Color.secondaryBackground.ignoresSafeArea())
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showDateRangePicker = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primaryGradient)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showDateRangePicker = false
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func generateAndShareCSV() {
        isExporting = true
        
        Task {
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
                
                await MainActor.run {
                    self.csvURL = fileURL
                    self.isShareSheetPresented = true
                    self.isExporting = false
                }
                
            } catch {
                print("Failed to generate CSV: \(error.localizedDescription)")
                await MainActor.run {
                    self.isExporting = false
                }
            }
        }
    }
}

// MARK: - History Summary Header
struct HistorySummaryHeader: View {
    let totalExpenses: Double
    let totalSettlements: Double
    let itemCount: Int
    
    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            // Expenses
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundColor(.errorRed)
                    Text("Expenses")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                Text(totalExpenses.toCurrency())
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.errorRed)
                    .monospacedDigit()
            }
            
            Spacer()
            
            // Divider
            Capsule()
                .fill(Color.divider)
                .frame(width: 1, height: 40)
            
            Spacer()
            
            // Settlements
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("Received")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.caption)
                        .foregroundColor(.successGreen)
                }
                Text(totalSettlements.toCurrency())
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.successGreen)
                    .monospacedDigit()
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.large)
                        .stroke(Color.divider.opacity(0.3), lineWidth: 1)
                )
                .cardShadow()
        )
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - Modern Filter Chip View
struct ModernFilterChipView: View {
    @Binding var selectedFilter: HistoryView.FilterType
    @Binding var showDateRangePicker: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(HistoryView.FilterType.allCases) { filter in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                        if filter == .dateRange {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showDateRangePicker = true
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            if filter == .dateRange {
                                Image(systemName: "calendar")
                                    .font(.caption)
                            }
                            Text(filter.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(
                            Group {
                                if selectedFilter == filter {
                                    Capsule()
                                        .fill(Color.primaryGradient)
                                        .glowShadow(color: Color.brandMagenta)
                                } else {
                                    Capsule()
                                        .fill(Color.cardBackground)
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.divider, lineWidth: 1.5)
                                        )
                                }
                            }
                        )
                        .foregroundColor(selectedFilter == filter ? .white : .brandMagenta)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }
}

// MARK: - Modern Expense Row
struct ModernExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Category Icon with Color Bar
            HStack(spacing: AppSpacing.sm) {
                Capsule()
                    .fill(Color(hex: expense.category?.colorHex ?? "#E91E63"))
                    .frame(width: 4, height: 50)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: expense.category?.colorHex ?? "#E91E63").opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: expense.category?.colorHex ?? "#E91E63"))
                }
            }
            
            // Expense Details
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.reason ?? expense.category?.name ?? "Uncategorized")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(expense.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
                .foregroundColor(.textSecondary)
                
                // Category tag if different from reason
                if let categoryName = expense.category?.name,
                   expense.reason != nil && expense.reason != categoryName {
                    Text(categoryName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: expense.category?.colorHex ?? "#E91E63"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color(hex: expense.category?.colorHex ?? "#E91E63").opacity(0.15))
                        )
                }
            }
            
            Spacer()
            
            // Amount
            Text("-\(expense.amount.toCurrency())")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.errorRed)
                .monospacedDigit()
        }
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
    }
}

// MARK: - Modern Settlement Row
struct ModernSettlementRow: View {
    let settlement: Settlement
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon with gradient
            HStack(spacing: AppSpacing.sm) {
                Capsule()
                    .fill(Color.successGreen)
                    .frame(width: 4, height: 50)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.successGreen.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.successGreen)
                }
            }
            
            // Settlement Details
            VStack(alignment: .leading, spacing: 4) {
                Text("Payment Received")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                    Text("from \(settlement.participantName)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(settlement.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
                .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Amount
            Text("+\(settlement.amount.toCurrency())")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.successGreen)
                .monospacedDigit()
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .fill(Color.cardBackground)
                .softShadow()
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .stroke(Color.successGreen.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Empty History View
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.primaryGradient.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.primaryGradient)
            }
            
            VStack(spacing: AppSpacing.sm) {
                Text("No Transactions Found")
                    .font(.title3.bold())
                    .foregroundColor(.textPrimary)
                
                Text("Try adjusting your filters or add some expenses to see your history")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Legacy compatibility
struct FilterChipView: View {
    @Binding var selectedFilter: HistoryView.FilterType
    @Binding var showDateRangePicker: Bool
    
    var body: some View {
        ModernFilterChipView(selectedFilter: $selectedFilter, showDateRangePicker: $showDateRangePicker)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [Expense.self, Settlement.self, Category.self], inMemory: true)
}
