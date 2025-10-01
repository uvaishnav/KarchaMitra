import SwiftUI
import Charts

struct DailySpending: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

struct SparklineView: View {
    let data: [DailySpending]
    var lineColor: Color = .brandCyan
    var showGradient: Bool = true
    
    private var maxAmount: Double {
        data.map { $0.amount }.max() ?? 0
    }
    
    private var minAmount: Double {
        data.map { $0.amount }.min() ?? 0
    }
    
    var body: some View {
        Chart(data) { item in
            // Area fill with gradient
            if showGradient {
                AreaMark(
                    x: .value("Date", item.date),
                    y: .value("Amount", item.amount)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            lineColor.opacity(0.3),
                            lineColor.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            // Line mark
            LineMark(
                x: .value("Date", item.date),
                y: .value("Amount", item.amount)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.brandMagenta, lineColor],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: (minAmount * 0.9)...(maxAmount * 1.1))
        .frame(height: 40)
    }
}

// MARK: - Enhanced Sparkline with Legend
struct SparklineWithLegend: View {
    let data: [DailySpending]
    let title: String
    var lineColor: Color = .brandCyan
    
    private var totalAmount: Double {
        data.reduce(0) { $0 + $1.amount }
    }
    
    private var averageAmount: Double {
        data.isEmpty ? 0 : totalAmount / Double(data.count)
    }
    
    private var trend: String {
        guard data.count >= 2 else { return "→" }
        let first = data.prefix(data.count / 2).reduce(0.0) { $0 + $1.amount }
        let second = data.suffix(data.count / 2).reduce(0.0) { $0 + $1.amount }
        
        if second > first * 1.1 {
            return "↗"
        } else if second < first * 0.9 {
            return "↘"
        } else {
            return "→"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    HStack(spacing: 4) {
                        Text(averageAmount.toCurrency())
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                            .monospacedDigit()
                        
                        Text(trend)
                            .font(.caption)
                            .foregroundColor(lineColor)
                    }
                }
                
                Spacer()
            }
            
            SparklineView(data: data, lineColor: lineColor, showGradient: true)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .fill(Color.cardBackground)
                .softShadow()
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        // Basic Sparkline
        SparklineView(
            data: [
                DailySpending(date: Date().addingTimeInterval(-86400 * 6), amount: 100),
                DailySpending(date: Date().addingTimeInterval(-86400 * 5), amount: 150),
                DailySpending(date: Date().addingTimeInterval(-86400 * 4), amount: 120),
                DailySpending(date: Date().addingTimeInterval(-86400 * 3), amount: 200),
                DailySpending(date: Date().addingTimeInterval(-86400 * 2), amount: 180),
                DailySpending(date: Date().addingTimeInterval(-86400), amount: 160),
                DailySpending(date: Date(), amount: 190)
            ]
        )
        .frame(width: 120, height: 40)
        
        // With Legend
        SparklineWithLegend(
            data: [
                DailySpending(date: Date().addingTimeInterval(-86400 * 6), amount: 100),
                DailySpending(date: Date().addingTimeInterval(-86400 * 5), amount: 150),
                DailySpending(date: Date().addingTimeInterval(-86400 * 4), amount: 120),
                DailySpending(date: Date().addingTimeInterval(-86400 * 3), amount: 200),
                DailySpending(date: Date().addingTimeInterval(-86400 * 2), amount: 180),
                DailySpending(date: Date().addingTimeInterval(-86400), amount: 160),
                DailySpending(date: Date(), amount: 190)
            ],
            title: "Daily Spending"
        )
        .padding()
    }
}
