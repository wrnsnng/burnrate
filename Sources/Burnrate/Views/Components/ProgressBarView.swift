import SwiftUI

struct ProgressBarView: View {
    let value: Double
    let label: String
    let resetsAt: Date?

    @State private var animatedValue: Double = 0
    @State private var isHovered = false

    private var percentage: Int {
        Int(value.rounded())
    }

    private var glowColor: Color {
        if value >= 90 {
            return BurnrateTheme.statusRed
        } else if value >= 70 {
            return BurnrateTheme.statusOrange
        }
        return Color(hex: 0x3B82F6)
    }

    private var isResetPending: Bool {
        guard let resetsAt = resetsAt else { return false }
        return resetsAt.timeIntervalSinceNow <= 0
    }

    private var shouldPulse: Bool {
        value >= 80 && !isResetPending
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BurnrateTheme.spacingXS) {
            // Label row
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BurnrateTheme.textSecondary)

                Spacer()

                Text(isResetPending ? "\(percentage)% (previous)" : "\(percentage)%")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(
                        isResetPending ? BurnrateTheme.textTertiary :
                        value >= 90 ? BurnrateTheme.statusRed :
                        value >= 70 ? BurnrateTheme.statusOrange :
                        BurnrateTheme.textPrimary
                    )
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.08))

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(BurnrateTheme.progressGradient(for: value))
                        .frame(width: max(0, geometry.size.width * min(animatedValue, 100) / 100))
                        .opacity(isResetPending ? 0.5 : 1.0)
                        .pulsingGlow(color: glowColor, isActive: shouldPulse)
                }
            }
            .frame(height: 6)

            // Reset time
            if let resetsAt = resetsAt {
                if isResetPending {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Previous cycle")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(BurnrateTheme.textSecondary)
                        Text("New cycle starts on next session")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundStyle(BurnrateTheme.textTertiary)
                    }
                } else {
                    Text("Resets \(formatTimeRemaining(resetsAt))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(BurnrateTheme.textTertiary)
                }
            }
        }
        .padding(BurnrateTheme.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                .fill(isHovered ? BurnrateTheme.cardBackgroundHover : BurnrateTheme.cardBackground)
        )
        .onHover { hovering in
            withAnimation(BurnrateTheme.easeOut) {
                isHovered = hovering
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.easeOut(duration: 0.3)) {
                animatedValue = newValue
            }
        }
    }

    private func formatTimeRemaining(_ date: Date) -> String {
        let now = Date()
        let remaining = date.timeIntervalSince(now)

        if remaining <= 0 {
            return "now"
        }

        let days = Int(remaining / 86400)
        let hours = Int(remaining.truncatingRemainder(dividingBy: 86400) / 3600)
        let minutes = Int(remaining.truncatingRemainder(dividingBy: 3600) / 60)

        if days > 0 {
            return "in \(days)d \(hours)h"
        } else if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else {
            return "in \(minutes)m"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ProgressBarView(value: 35, label: "5-hour", resetsAt: Date().addingTimeInterval(3600))
        ProgressBarView(value: 72, label: "7-day", resetsAt: Date().addingTimeInterval(86400))
        ProgressBarView(value: 95, label: "Opus", resetsAt: nil)
        ProgressBarView(value: 85, label: "Reset pending", resetsAt: Date().addingTimeInterval(-3600))
    }
    .padding()
    .frame(width: 300)
    .background(Color(NSColor.windowBackgroundColor))
}
