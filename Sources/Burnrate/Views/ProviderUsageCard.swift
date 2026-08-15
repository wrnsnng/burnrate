import SwiftUI

struct ProviderUsageCard: View {
    let providerInfo: ProviderInfo
    let usage: ProviderUsage?
    let isInstalled: Bool
    let hasTracking: Bool
    @Binding var isExpanded: Bool
    var extraContent: AnyView? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tappable header
            Button {
                withAnimation(BurnrateTheme.springSnappy) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: BurnrateTheme.spacingSM) {
                    BrandIcon(providerId: providerInfo.id, size: 11)
                        .foregroundStyle(providerInfo.color)
                        .frame(width: 20, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(providerInfo.color.opacity(0.12))
                        )

                    Text(providerInfo.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(BurnrateTheme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Spacer()

                    // Status indicator
                    if let usage = usage {
                        let maxUtil = max(usage.primaryUtilization, usage.secondaryUtilization ?? 0)
                        Circle()
                            .fill(statusColor(for: maxUtil))
                            .frame(width: 6, height: 6)
                    } else if isInstalled {
                        Circle()
                            .fill(BurnrateTheme.textTertiary)
                            .frame(width: 6, height: 6)
                    }

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(BurnrateTheme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(BurnrateTheme.springSnappy, value: isExpanded)
                }
                .padding(.vertical, BurnrateTheme.spacingXS)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expandable detail
            if isExpanded {
                VStack(alignment: .leading, spacing: BurnrateTheme.spacingSM) {
                    if let usage = usage {
                        VStack(spacing: BurnrateTheme.spacingXS) {
                            ProgressBarView(
                                value: usage.primaryUtilization,
                                label: usage.primaryLabel,
                                resetsAt: usage.primaryResetsAt
                            )

                            if let secondary = usage.secondaryUtilization,
                               let secondaryLabel = usage.secondaryLabel {
                                ProgressBarView(
                                    value: secondary,
                                    label: secondaryLabel,
                                    resetsAt: usage.secondaryResetsAt
                                )
                            }
                        }

                        if let extraContent = extraContent {
                            extraContent
                        }
                    } else if !isInstalled {
                        ProviderNotInstalledRow(
                            info: providerInfo
                        )
                    } else if !hasTracking {
                        ProviderComingSoonRow(info: providerInfo)
                    } else {
                        HStack(spacing: BurnrateTheme.spacingSM) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(BurnrateTheme.textTertiary)

                            Text("No recent usage data")
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
                .padding(.top, BurnrateTheme.spacingSM)
                .transition(.opacity)
            }
        }
    }

    private func statusColor(for utilization: Double) -> Color {
        if utilization >= 90 { return BurnrateTheme.statusRed }
        if utilization >= 70 { return BurnrateTheme.statusOrange }
        return BurnrateTheme.statusGreen
    }
}

// MARK: - Provider Not Installed Row

struct ProviderNotInstalledRow: View {
    let info: ProviderInfo

    var body: some View {
        VStack(alignment: .leading, spacing: BurnrateTheme.spacingSM) {
            HStack(spacing: BurnrateTheme.spacingMD) {
                BrandIcon(providerId: info.id, size: 14)
                    .foregroundStyle(BurnrateTheme.textTertiary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                            .fill(BurnrateTheme.surfaceSecondary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(info.unavailableMessage)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(BurnrateTheme.textTertiary)

                    if let cmd = info.installCommand {
                        Text(cmd)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(info.color.opacity(0.7))
                            .textSelection(.enabled)
                    }
                }

                Spacer()
            }
        }
        .padding(BurnrateTheme.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                .fill(BurnrateTheme.cardBackground)
        )
    }
}

// MARK: - Provider Coming Soon Row

struct ProviderComingSoonRow: View {
    let info: ProviderInfo

    var body: some View {
        HStack(spacing: BurnrateTheme.spacingMD) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(info.color.opacity(0.5))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                        .fill(info.color.opacity(0.06))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Installed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BurnrateTheme.textSecondary)

                Text("Usage tracking coming soon")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(BurnrateTheme.textTertiary)
            }

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
    struct PreviewWrapper: View {
        @State var expanded1 = true
        @State var expanded2 = true
        @State var expanded3 = true

        var body: some View {
            VStack(spacing: 16) {
                ProviderUsageCard(
                    providerInfo: ProviderInfo(id: "claude", name: "Claude", icon: "message.fill", brandColor: 0xDA7756, unavailableMessage: ""),
                    usage: ProviderUsage(
                        primaryUtilization: 35,
                        primaryLabel: "5-hour",
                        primaryResetsAt: Date().addingTimeInterval(3600),
                        secondaryUtilization: 72,
                        secondaryLabel: "7-day",
                        secondaryResetsAt: Date().addingTimeInterval(86400),
                        extraInfo: nil
                    ),
                    isInstalled: true,
                    hasTracking: true,
                    isExpanded: $expanded1
                )

                ProviderUsageCard(
                    providerInfo: ProviderInfo(id: "codex", name: "Codex", icon: "terminal.fill", brandColor: 0x10A37F, unavailableMessage: "Install Codex CLI", installCommand: "npm install -g @openai/codex"),
                    usage: nil,
                    isInstalled: false,
                    hasTracking: true,
                    isExpanded: $expanded2
                )

                ProviderUsageCard(
                    providerInfo: ProviderInfo(id: "kimi", name: "Kimi K2.5", icon: "sparkles", brandColor: 0x6366F1, unavailableMessage: ""),
                    usage: nil,
                    isInstalled: true,
                    hasTracking: false,
                    isExpanded: $expanded3
                )
            }
            .padding()
            .frame(width: 320)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }

    return PreviewWrapper()
}
