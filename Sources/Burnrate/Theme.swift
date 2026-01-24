import SwiftUI

// MARK: - Burnrate Theme

enum BurnrateTheme {
    // MARK: Colors

    static let accentGradient = LinearGradient(
        colors: [Color(hex: 0xF97316), Color(hex: 0xEA580C)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGlow = Color(hex: 0xF97316).opacity(0.15)

    static let cardBackground = Color.primary.opacity(0.04)
    static let cardBackgroundHover = Color.primary.opacity(0.08)
    static let cardBorder = Color.primary.opacity(0.06)

    static let surfaceSecondary = Color.primary.opacity(0.03)

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.primary.opacity(0.4)

    // Status colors
    static let statusGreen = Color(hex: 0x22C55E)
    static let statusYellow = Color(hex: 0xEAB308)
    static let statusOrange = Color(hex: 0xF97316)
    static let statusRed = Color(hex: 0xEF4444)

    // Progress bar gradients
    static func progressGradient(for value: Double) -> LinearGradient {
        if value >= 90 {
            return LinearGradient(
                colors: [Color(hex: 0xEF4444), Color(hex: 0xDC2626)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if value >= 70 {
            return LinearGradient(
                colors: [Color(hex: 0xF97316), Color(hex: 0xEA580C)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [Color(hex: 0x3B82F6), Color(hex: 0x2563EB)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    // MARK: Spacing

    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 20
    static let spacing2XL: CGFloat = 24

    // MARK: Corner Radius

    static let radiusSM: CGFloat = 6
    static let radiusMD: CGFloat = 10
    static let radiusLG: CGFloat = 14

    // MARK: Animation

    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let springGentle = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let easeOut = Animation.easeOut(duration: 0.2)
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

// MARK: - Styled Card

struct StyledCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = BurnrateTheme.spacingMD

    init(padding: CGFloat = BurnrateTheme.spacingMD, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: BurnrateTheme.radiusMD)
                    .fill(BurnrateTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: BurnrateTheme.radiusMD)
                            .strokeBorder(BurnrateTheme.cardBorder, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String
    var iconColor: Color = BurnrateTheme.textSecondary

    var body: some View {
        HStack(spacing: BurnrateTheme.spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 20, height: 20)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(iconColor.opacity(0.12))
                )

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(BurnrateTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }
}

// MARK: - Action Button Style

struct ActionButtonStyle: ButtonStyle {
    @State private var isHovered = false
    var isDestructive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(isDestructive ? BurnrateTheme.textTertiary : BurnrateTheme.textSecondary)
            .padding(.horizontal, BurnrateTheme.spacingMD)
            .padding(.vertical, BurnrateTheme.spacingSM)
            .background(
                RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                    .fill(isHovered ? BurnrateTheme.cardBackgroundHover : BurnrateTheme.cardBackground)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(BurnrateTheme.easeOut, value: configuration.isPressed)
            .onHover { hovering in
                withAnimation(BurnrateTheme.easeOut) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Icon Button Style

struct IconButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(isHovered ? BurnrateTheme.textPrimary : BurnrateTheme.textSecondary)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                    .fill(isHovered ? BurnrateTheme.cardBackgroundHover : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(BurnrateTheme.easeOut, value: configuration.isPressed)
            .onHover { hovering in
                withAnimation(BurnrateTheme.easeOut) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Pulsing Glow Modifier

struct PulsingGlow: ViewModifier {
    let color: Color
    let isActive: Bool
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: isActive ? color.opacity(isPulsing ? 0.4 : 0.2) : .clear,
                radius: isPulsing ? 8 : 4,
                x: 0,
                y: 0
            )
            .onAppear {
                guard isActive else { return }
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulsingGlow(color: Color, isActive: Bool) -> some View {
        modifier(PulsingGlow(color: color, isActive: isActive))
    }
}

// MARK: - Shimmer Loading

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.1),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 300
                    }
                }
            )
            .clipped()
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
