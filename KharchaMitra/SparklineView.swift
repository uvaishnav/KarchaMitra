import SwiftUI
import Charts

struct DailySpending: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

struct SparklineView: View {
    let data: [DailySpending]
    
    var body: some View {
        Chart(data) { item in
            LineMark(
                x: .value("Date", item.date),
                y: .value("Amount", item.amount)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(.blue)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(width: 100, height: 30)
    }
}
