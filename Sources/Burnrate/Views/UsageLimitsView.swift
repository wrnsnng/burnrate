import SwiftUI

struct UsageLimitsView: View {
    let limits: UsageLimits?
    let isTokenExpired: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: BurnrateTheme.spacingMD) {
            SectionHeader(
                title: "Usage",
                icon: "chart.bar.fill",
                iconColor: Color(hex: 0x3B82F6)
            )

            if let limits = limits {
                VStack(spacing: BurnrateTheme.spacingSM) {
                    ProgressBarView(
                        value: limits.fiveHourUtilization,
                        label: "5-hour",
                        resetsAt: limits.fiveHourResetsAt
                    )

                    ProgressBarView(
                        value: limits.sevenDayUtilization,
                        label: "7-day",
                        resetsAt: limits.sevenDayResetsAt
                    )

                    if limits.opusUtilization > 0 || limits.opusResetsAt != nil {
                        ProgressBarView(
                            value: limits.opusUtilization,
                            label: "Opus",
                            resetsAt: limits.opusResetsAt
                        )
                    }
                }
            } else if isTokenExpired {
                TokenExpiredView()
            } else {
                EmptyStateView(
                    icon: "chart.bar.xaxis",
                    message: "Unable to fetch limits"
                )
            }
        }
    }
}

// MARK: - Token Expired View

struct TokenExpiredView: View {
    var body: some View {
        HStack(spacing: BurnrateTheme.spacingMD) {
            Image(systemName: "key.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BurnrateTheme.statusOrange)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                        .fill(BurnrateTheme.statusOrange.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Token expired")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BurnrateTheme.textPrimary)

                Text("Run 'claude' to refresh")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(BurnrateTheme.textTertiary)
            }

            Spacer()
        }
        .padding(BurnrateTheme.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: BurnrateTheme.radiusMD)
                .fill(BurnrateTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: BurnrateTheme.radiusMD)
                        .strokeBorder(BurnrateTheme.statusOrange.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        HStack(spacing: BurnrateTheme.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(BurnrateTheme.textTertiary)

            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(BurnrateTheme.textTertiary)

            Spacer()
        }
        .padding(BurnrateTheme.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                .fill(BurnrateTheme.cardBackground)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        UsageLimitsView(
            limits: UsageLimits(
                fiveHourUtilization: 35,
                fiveHourResetsAt: Date().addingTimeInterval(3600),
                sevenDayUtilization: 72,
                sevenDayResetsAt: Date().addingTimeInterval(86400 * 3),
                opusUtilization: 15,
                opusResetsAt: Date().addingTimeInterval(86400 * 5)
            ),
            isTokenExpired: false
        )

        UsageLimitsView(limits: nil, isTokenExpired: true)
    }
    .padding()
    .frame(width: 320)
    .background(Color(NSColor.windowBackgroundColor))
}
