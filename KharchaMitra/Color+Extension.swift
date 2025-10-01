import SwiftUI

extension Color {
    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
    
    // MARK: - Brand Colors (Primary Identity)
    static let brandMagenta = Color(hex: "E91E63")
    static let brandCyan = Color(hex: "00BCD4")
    static let brandOrangeStart = Color(hex: "#FF9800")
    static let brandOrangeEnd = Color(hex: "#FF5722")
    static let brandDarkMagenta = Color(hex: "C2185B")
    static let brandLightPink = Color(hex: "F48FB1")
    static let brandAccentCyan = Color(hex: "26C6DA")
    static let brandTeal = Color(hex: "009688")
    
    // MARK: - Semantic Colors (Financial Context)
    static let successGreen = Color(hex: "10B981")
    static let successLight = Color(hex: "34D399")
    static let warningOrange = Color(hex: "F59E0B")
    static let warningLight = Color(hex: "FBBF24")
    static let errorRed = Color(hex: "EF4444")
    static let errorLight = Color(hex: "F87171")
    static let infoBlue = Color(hex: "3B82F6")
    static let infoLight = Color(hex: "60A5FA")
    
    // MARK: - Gradient Definitions
    static let primaryGradient = LinearGradient(
        colors: [brandOrangeStart, brandOrangeEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let primaryGradientHorizontal = LinearGradient(
        colors: [brandOrangeStart, brandOrangeEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let successGradient = LinearGradient(
        colors: [successGreen, Color(hex: "059669")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [warningOrange, Color(hex: "F97316")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let errorGradient = LinearGradient(
        colors: [errorRed, Color(hex: "DC2626")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let subtleGradient = LinearGradient(
        colors: [brandMagenta.opacity(0.1), brandCyan.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Category Colors (Vibrant & Accessible)
    static let categoryColors: [Color] = [
        Color(hex: "E91E63"), // Magenta - Needs
        Color(hex: "00BCD4"), // Cyan - Wants
        Color(hex: "9C27B0"), // Purple - Bills
        Color(hex: "FF9800"), // Orange - Transport
        Color(hex: "4CAF50"), // Green - Savings
        Color(hex: "FF5722"), // Deep Orange - Entertainment
        Color(hex: "673AB7"), // Deep Purple - Health
        Color(hex: "009688"), // Teal - Education
        Color(hex: "FFC107"), // Amber - Shopping
        Color(hex: "795548"), // Brown - Food
    ]
    
    // MARK: - UI Element Colors (Light Mode)
    static let cardBackground = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary = Color(UIColor.tertiaryLabel)
    static let divider = Color(UIColor.separator)
    
    // MARK: - Shadow Helpers
    static func shadowColor(_ color: Color, opacity: Double = 0.3) -> Color {
        return color.opacity(opacity)
    }
}

// MARK: - Gradient Presets for Components
extension LinearGradient {
    static func budgetProgress(percentage: Double) -> LinearGradient {
        if percentage < 0.5 {
            return LinearGradient(
                colors: [Color.successGreen, Color(hex: "34D399")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if percentage < 0.75 {
            return LinearGradient(
                colors: [Color(hex: "10B981"), Color(hex: "14B8A6")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if percentage < 0.9 {
            return LinearGradient(
                colors: [Color.warningOrange, Color.warningLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.errorRed, Color.errorLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Design System Spacing
enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Design System Corner Radius
enum AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 20
    static let xxLarge: CGFloat = 24
}

// MARK: - Design System Shadows
extension View {
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    func elevatedShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 8)
    }
    
    func softShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
    
    func glowShadow(color: Color) -> some View {
        self.shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

