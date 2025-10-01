import SwiftUI

struct BudgetProgressView: View {
    let limit: Double
    let spending: Double
    let safeLimit: Double
    let limitLeft: Double

    // Pulse animation state
    @State private var isPulsing = false

    private var progress: Double {
        if limit > 0 {
            return spending / limit
        }
        return 0
    }
    
    // Spending Velocity Calculation
    private var dailySpendingRate: Double {
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: Date())
        guard dayOfMonth > 0 else { return spending }
        return spending / Double(dayOfMonth)
    }
    
    private var targetDailyRate: Double {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: Date()) else { return limit }
        let numDays = range.count
        guard numDays > 0 else { return limit }
        return limit / Double(numDays)
    }
    
    private var velocityColor: Color {
        if dailySpendingRate <= targetDailyRate {
            return .green
        } else if dailySpendingRate <= targetDailyRate * 1.25 {
            return .orange
        } else {
            return .red
        }
    }

    private var progressGradient: LinearGradient {
        if progress < 0.5 {
            return LinearGradient(gradient: Gradient(colors: [.green, .cyan]), startPoint: .top, endPoint: .bottom)
        } else if progress < 0.9 {
            return LinearGradient(gradient: Gradient(colors: [.orange, .yellow]), startPoint: .top, endPoint: .bottom)
        } else {
            return LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .top, endPoint: .bottom)
        }
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
        VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 20.0)
                    .opacity(0.1)
                    .foregroundColor(.gray)

                Circle()
                    .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 20.0, lineCap: .round, lineJoin: .round))
                    .fill(progressGradient)
                    .rotationEffect(Angle(degrees: 270.0))
                    .shadow(color: progressColor.opacity(0.5), radius: 10, x: 0, y: 5)
                
                // Pulse effect
                Circle()
                    .stroke(progressColor.opacity(0.5), lineWidth: 2)
                    .frame(width: 250, height: 250)
                    .scaleEffect(isPulsing ? 1.15 : 1.0)
                    .opacity(isPulsing ? 0 : 1)

                VStack {
                    Text("Safe Limit")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(safeLimit.toCurrency())
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("Limit Left")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Text(limitLeft.toCurrency())
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                }
            }
            .frame(width: 250, height: 250)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Spending Velocity")
                        .font(.caption.weight(.bold)).foregroundColor(.secondary)
                    Text("Your current daily average.")
                        .font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                Text(dailySpendingRate.toCurrency())
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(velocityColor)
                Image(systemName: dailySpendingRate <= targetDailyRate ? "arrow.down.right" : "arrow.up.right")
                    .foregroundColor(velocityColor)
            }
            .padding(.top)

        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .background(.ultraThinMaterial.opacity(0.8))
        .cornerRadius(20)
        .padding(.horizontal)
        .onChange(of: progress) { oldValue, newValue in
            if newValue > 0.9 && !isPulsing {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else if newValue <= 0.9 && isPulsing {
                isPulsing = false
            }
        }
        .animation(.easeInOut(duration: 0.8), value: progress)
    }
}
