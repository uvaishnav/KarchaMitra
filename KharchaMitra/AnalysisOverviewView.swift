import SwiftUI
import SwiftData
import Charts

struct AnalysisOverviewView: View {
    @Query var expenses: [Expense]
    @Query var settings: [UserSettings]
    var isForPDF: Bool = false

    @State private var selectedWantNeedAmount: Double?
    @State private var selectedRecurringAmount: Double?

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    private var monthlyExpenses: [Expense] {
        expenses.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }

    private var wantVsNeedSpending: [CategorySpending] {
        let dictionary = Dictionary(grouping: monthlyExpenses, by: { $0.category?.type ?? .need })
        return dictionary.map { (type, expensesInType) in
            let grossSpent = expensesInType.reduce(0) { $0 + $1.amount }
            let totalRecovered = expensesInType.flatMap { $0.sharedParticipants }.reduce(0) { $0 + $1.amountPaid }
            let netSpent = grossSpent - totalRecovered
            return CategorySpending(categoryName: type.displayName, amount: netSpent, categoryType: type)
        }
    }
    
    private var recurringVsOneTimeSpending: [SpendingType] {
        let recurringExpenses = monthlyExpenses.filter { $0.recurringTemplate != nil }
        let oneTimeExpenses = monthlyExpenses.filter { $0.recurringTemplate == nil }
        
        let recurringGross = recurringExpenses.reduce(0) { $0 + $1.amount }
        let recurringRecovered = recurringExpenses.flatMap { $0.sharedParticipants }.reduce(0) { $0 + $1.amountPaid }
        let recurringNet = recurringGross - recurringRecovered
        
        let oneTimeGross = oneTimeExpenses.reduce(0) { $0 + $1.amount }
        let oneTimeRecovered = oneTimeExpenses.flatMap { $0.sharedParticipants }.reduce(0) { $0 + $1.amountPaid }
        let oneTimeNet = oneTimeGross - oneTimeRecovered
        
        return [
            SpendingType(name: "Recurring", amount: recurringNet),
            SpendingType(name: "One-Time", amount: oneTimeNet)
        ]
    }
    
    private var totalSpending: Double {
        let grossSpent = monthlyExpenses.reduce(0) { $0 + $1.amount }
        let totalRecovered = monthlyExpenses.flatMap { $0.sharedParticipants }.reduce(0) { $0 + $1.amountPaid }
        return grossSpent - totalRecovered
    }
    
    private var monthlySpendingAgainstLimit: Double {
        let limitedExpenses = expenses.filter { $0.category?.type != .UTR }
        
        let grossSpent = limitedExpenses.reduce(0) { $0 + $1.amount }
        
        let totalRecovered = limitedExpenses
            .flatMap { $0.sharedParticipants }
            .reduce(0) { $0 + $1.amountPaid }
            
        return grossSpent - totalRecovered
    }

    private var limitLeft: Double {
        userSettings.expenseLimit - monthlySpendingAgainstLimit
    }
    
    private var savingBuffer: Double {
        userSettings.savingBuffer
    }

    var body: some View {
        if isForPDF {
            content
        } else {
            ScrollView {
                content
            }
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            if monthlyExpenses.isEmpty {
                Text("Not enough data for this month yet.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                // Monthly Summary
                GroupBox("Monthly Summary") {
                    HStack {
                        VStack {
                            Text("Spending")
                            Text(totalSpending.toCurrency()).foregroundColor(.red)
                        }
                        Spacer()
                        VStack {
                            Text("Limit Left")
                            Text(limitLeft.toCurrency()).foregroundColor(limitLeft >= 0 ? .green : .orange)
                        }
                        Spacer()
                        VStack {
                            Text("Saving Buffer")
                            Text(savingBuffer.toCurrency()).foregroundColor(.blue)
                        }
                    }
                }

                // Want vs Need Pie Chart
                GroupBox("Wants vs. Needs vs. UTR") {
                    Chart(wantVsNeedSpending) { spending in
                        SectorMark(
                            angle: .value("Amount", spending.amount),
                            innerRadius: .ratio(0.618)
                        )
                        .foregroundStyle(by: .value("Type", spending.categoryName))
                        .opacity(selectedWantNeedAmount == nil ? 1.0 : (selectedWantNeedAmount == spending.amount ? 1.0 : 0.5))
                    }
                    .chartAngleSelection(value: $selectedWantNeedAmount)
                    .frame(height: 250)
                    .chartBackground {
                        chartProxy in
                        GeometryReader { geometry in
                            if let plotFrame = chartProxy.plotFrame {
                                let frame = geometry[plotFrame]
                                VStack {
                                    if let selectedWantNeedAmount {
                                        Text("Amount")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(selectedWantNeedAmount.toCurrency())
                                            .font(.headline.weight(.bold))
                                    } else {
                                        Text("Total")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(totalSpending.toCurrency())
                                            .font(.headline.weight(.bold))
                                    }
                                }
                                .position(x: frame.midX, y: frame.midY)
                            }
                        }
                    }
                }

                // Recurring vs One-Time Pie Chart
                GroupBox("Recurring vs. One-Time") {
                    Chart(recurringVsOneTimeSpending) { spending in
                        SectorMark(
                            angle: .value("Amount", spending.amount),
                            innerRadius: .ratio(0.618)
                        )
                        .foregroundStyle(by: .value("Type", spending.name))
                        .opacity(selectedRecurringAmount == nil ? 1.0 : (selectedRecurringAmount == spending.amount ? 1.0 : 0.5))
                    }
                    .chartAngleSelection(value: $selectedRecurringAmount)
                    .frame(height: 250)
                    .chartBackground { chartProxy in
                        GeometryReader { geometry in
                            if let plotFrame = chartProxy.plotFrame {
                                let frame = geometry[plotFrame]
                                VStack {
                                    if let selectedRecurringAmount {
                                        Text("Amount")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(selectedRecurringAmount.toCurrency())
                                            .font(.headline.weight(.bold))
                                    } else {
                                        Text("Total")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(totalSpending.toCurrency())
                                            .font(.headline.weight(.bold))
                                    }
                                }
                                .position(x: frame.midX, y: frame.midY)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .onChange(of: selectedWantNeedAmount) { oldValue, newValue in
            if newValue != nil {
                hapticFeedback()
            }
        }
        .onChange(of: selectedRecurringAmount) { oldValue, newValue in
            if newValue != nil {
                hapticFeedback()
            }
        }
    }
    
    private func hapticFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}
