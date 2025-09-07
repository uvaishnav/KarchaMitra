
import SwiftUI
import SwiftData
import Charts

// A struct to represent spending in a specific category.
struct CategorySpending: Identifiable {
    let id = UUID()
    let categoryName: String
    let amount: Double
    let categoryType: CategoryType
}

struct AnalysisView: View {
    @Query var expenses: [Expense]
    
    // State for the CSV export
    @State private var isShareSheetPresented = false
    @State private var csvURL: URL? = nil

    init() {}

    private var monthlyExpenses: [Expense] {
        expenses.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }

    private var categorySpending: [CategorySpending] {
        let dictionary = Dictionary(grouping: monthlyExpenses, by: { $0.category?.name ?? "Uncategorized" })
        return dictionary.map {
            let category = $0.value.first?.category
            return CategorySpending(categoryName: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }, categoryType: category?.type ?? .need)
        }.sorted(by: { $0.amount > $1.amount })
    }

    private var wantVsNeedSpending: [CategorySpending] {
        let dictionary = Dictionary(grouping: monthlyExpenses, by: { $0.category?.type ?? .need })
        return dictionary.map {
            let typeName = $0.key == .need ? "Need" : "Want"
            return CategorySpending(categoryName: typeName, amount: $0.value.reduce(0) { $0 + $1.amount }, categoryType: $0.key)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Monthly Analysis")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)

                    if monthlyExpenses.isEmpty {
                        Text("Not enough data for this month yet.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        // Want vs Need Pie Chart
                        GroupBox("Wants vs. Needs") {
                            Chart(wantVsNeedSpending) { spending in
                                SectorMark(
                                    angle: .value("Amount", spending.amount),
                                    innerRadius: .ratio(0.618)
                                )
                                .foregroundStyle(by: .value("Type", spending.categoryName))
                                .annotation(position: .overlay) {
                                    Text("\(spending.amount.toCurrency())")
                                        .font(.caption)
                                        .bold()
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(height: 250)
                        }

                        // Spending by Category Pie Chart
                        GroupBox("Spending by Category") {
                            Chart(categorySpending) { spending in
                                BarMark(
                                    x: .value("Amount", spending.amount),
                                    y: .value("Category", spending.categoryName)
                                )
                                .foregroundStyle(by: .value("Category", spending.categoryName))
                            }
                            .chartLegend(.hidden)
                            .frame(height: 300)
                        }
                        
                        // AI Insights Placeholder
                        GroupBox("AI Insights") {
                            Text(PredictionService().generateInsight(from: monthlyExpenses))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Analysis")
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
        }
    }
    
    private func generateAndShareCSV() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "KharchaMitra_Export_\(dateFormatter.string(from: Date())).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var csvText = "Date,Amount,Category,Type,Reason\n"
        
        let sortedExpenses = expenses.sorted(by: { $0.date < $1.date })
        
        for expense in sortedExpenses {
            let date = dateFormatter.string(from: expense.date)
            let amount = String(expense.amount)
            let category = expense.category?.name ?? "N/A"
            let type = expense.category?.type == .need ? "Need" : "Want"
            let reason = expense.reason?.replacingOccurrences(of: ",", with: "") ?? ""
            csvText.append("\(date),\(amount),\(category),\(type),\(reason)\n")
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

// A wrapper for the UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    AnalysisView()
        .modelContainer(for: [Expense.self, Category.self], inMemory: true)
}
