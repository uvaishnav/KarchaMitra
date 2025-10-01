import SwiftUI

struct BudgetProgressView: View {
    let limit: Double
    let spending: Double
    let safeLimit: Double
    let limitLeft: Double

    // Animation states
    @State private var isPulsing = false
    @State private var animateProgress = false
    @State private var showDetails = false

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
            return .successGreen
        } else if dailySpendingRate <= targetDailyRate * 1.25 {
            return .warningOrange
        } else {
            return .errorRed
        }
    }

    private var progressGradient: LinearGradient {
        return LinearGradient.budgetProgress(percentage: progress)
    }
    
    private var progressColor: Color {
        if progress < 0.5 {
            return .successGreen
        } else if progress < 0.75 {
            return Color(hex: "14B8A6") // Teal
        } else if progress < 0.9 {
            return .warningOrange
        } else {
            return .errorRed
        }
    }
    
    private var percentageText: String {
        return String(format: "%.0f%%", min(progress * 100, 100))
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Circular Progress with Modern Styling
            ZStack {
                // Background circle with subtle gradient
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 22
                    )
                
                // Animated progress circle
                Circle()
                    .trim(from: 0.0, to: animateProgress ? CGFloat(min(progress, 1.0)) : 0.0)
                    .stroke(
                        progressGradient,
                        style: StrokeStyle(
                            lineWidth: 22,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.spring(response: 1.2, dampingFraction: 0.8), value: animateProgress)
                    .glowShadow(color: progressColor)
                
                // Pulse effect for over-budget warning
                if progress > 0.9 {
                    Circle()
                        .stroke(progressColor.opacity(0.3), lineWidth: 3)
                        .scaleEffect(isPulsing ? 1.12 : 1.0)
                        .opacity(isPulsing ? 0 : 0.8)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
                }
                
                // Center content with improved hierarchy
                VStack(spacing: AppSpacing.xs) {
                    // Percentage indicator
                    Text(percentageText)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(progressColor)
                        .scaleEffect(showDetails ? 1.0 : 0.8)
                        .opacity(showDetails ? 1.0 : 0.0)
                    
                    // Safe Limit
                    VStack(spacing: 2) {
                        Text("Safe Limit")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Text(safeLimit.toCurrency())
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.brandCyan)
                            .monospacedDigit()
                    }
                    .scaleEffect(showDetails ? 1.0 : 0.8)
                    .opacity(showDetails ? 1.0 : 0.0)
                    
                    Divider()
                        .frame(width: 60)
                        .padding(.vertical, AppSpacing.xs)
                        .opacity(showDetails ? 0.3 : 0.0)
                    
                    // Limit Left
                    VStack(spacing: 2) {
                        Text("Remaining")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Text(limitLeft.toCurrency())
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(limitLeft >= 0 ? Color.successGreen : Color.errorRed)
                            .monospacedDigit()
                    }
                    .scaleEffect(showDetails ? 1.0 : 0.8)
                    .opacity(showDetails ? 1.0 : 0.0)
                }
            }
            .frame(width: 260, height: 260)
            .padding(AppSpacing.lg)
            
            // Spending Velocity Card (Modern Design)
            HStack(spacing: AppSpacing.md) {
                // Icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(velocityColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: dailySpendingRate <= targetDailyRate ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(velocityColor)
                        .symbolEffect(.bounce, value: dailySpendingRate)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spending Velocity")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Your current daily average")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Amount with indicator
                VStack(alignment: .trailing, spacing: 2) {
                    Text(dailySpendingRate.toCurrency())
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(velocityColor)
                        .monospacedDigit()
                    
                    HStack(spacing: 2) {
                        Image(systemName: dailySpendingRate <= targetDailyRate ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.caption2)
                        Text(dailySpendingRate <= targetDailyRate ? "On Track" : "High")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(velocityColor)
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .fill(Color.cardBackground)
                    .softShadow()
            )
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.xLarge)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.xLarge)
                        .fill(Color.subtleGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.xLarge)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .cardShadow()
        )
        .padding(.horizontal, AppSpacing.md)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animateProgress = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                showDetails = true
            }
            if progress > 0.9 {
                isPulsing = true
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            if newValue > 0.9 && !isPulsing {
                withAnimation {
                    isPulsing = true
                }
            } else if newValue <= 0.9 && isPulsing {
                isPulsing = false
            }
        }
    }
}

