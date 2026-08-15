import SwiftUI

struct CodexUsageLimitsView: View {
    let limits: CodexUsageLimits?
    let isCodexInstalled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: BurnrateTheme.spacingMD) {
            SectionHeader(
                title: "Usage",
                icon: "chart.bar.fill",
                iconColor: Color(hex: 0x10A37F) // OpenAI green
            )

            if let limits = limits {
                VStack(spacing: BurnrateTheme.spacingSM) {
                    ProgressBarView(
                        value: limits.fiveHourUtilization,
                        label: "5-hour",
                        resetsAt: limits.fiveHourResetsAt
                    )

                    ProgressBarView(
                        value: limits.weeklyUtilization,
                        label: "Weekly",
                        resetsAt: limits.weeklyResetsAt
                    )
                }
            } else if !isCodexInstalled {
                CodexNotInstalledView()
            } else {
                EmptyStateView(
                    icon: "chart.bar.xaxis",
                    message: "No recent Codex sessions"
                )
            }
        }
    }
}

// MARK: - Codex Not Installed View

struct CodexNotInstalledView: View {
    var body: some View {
        HStack(spacing: BurnrateTheme.spacingMD) {
            Image(systemName: "terminal")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BurnrateTheme.textTertiary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                        .fill(BurnrateTheme.surfaceSecondary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Codex not installed")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BurnrateTheme.textPrimary)

                Text("Install from openai.com/codex")
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
                        .strokeBorder(BurnrateTheme.cardBorder, lineWidth: 1)
                )
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        CodexUsageLimitsView(
            limits: CodexUsageLimits(
                fiveHourUtilization: 25,
                fiveHourResetsAt: Date().addingTimeInterval(3600),
                weeklyUtilization: 45,
                weeklyResetsAt: Date().addingTimeInterval(86400 * 3),
                inputTokens: 10000,
                outputTokens: 5000,
                reasoningTokens: 2000
            ),
            isCodexInstalled: true
        )

        CodexUsageLimitsView(limits: nil, isCodexInstalled: false)

        CodexUsageLimitsView(limits: nil, isCodexInstalled: true)
    }
    .padding()
    .frame(width: 320)
    .background(Color(NSColor.windowBackgroundColor))
}
