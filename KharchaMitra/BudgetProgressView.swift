import SwiftUI

struct BudgetProgressView: View {
    let limit: Double
    let spending: Double
    let safeLimit: Double
    let limitLeft: Double

    private var progress: Double {
        if limit > 0 {
            return spending / limit
        }
        return 0
    }

    private var progressColor: Color {
        if progress < 0.5 {
            return .green
        } else if progress < 0.9 {
            return .orange
        } else {
            return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20.0)
                .opacity(0.3)
                .foregroundColor(progressColor)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 20.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(progressColor)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)

            VStack {
                Text("Safe Limit")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(safeLimit.toCurrency())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Limit Left: \(limitLeft.toCurrency())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 250, height: 250)
        .padding()
    }
}
