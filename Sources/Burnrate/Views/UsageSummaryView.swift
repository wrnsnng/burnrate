import SwiftUI

struct UsageSummaryView: View {
    let providerInfos: [ProviderInfo]
    let providerUsages: [String: ProviderUsage]
    let isInstalled: (String) -> Bool
    let hasTracking: (String) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: BurnrateTheme.spacingSM) {
            SectionHeader(
                title: "Overview",
                icon: "square.grid.2x2.fill",
                iconColor: Color(hex: 0x8B5CF6)
            )

            VStack(spacing: 2) {
                ForEach(providerInfos, id: \.id) { info in
                    SummaryRow(
                        info: info,
                        usage: providerUsages[info.id],
                        installed: isInstalled(info.id),
                        tracked: hasTracking(info.id)
                    )
                }
            }
            .padding(BurnrateTheme.spacingSM)
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
}

// MARK: - Summary Row

private struct SummaryRow: View {
    let info: ProviderInfo
    let usage: ProviderUsage?
    let installed: Bool
    let tracked: Bool

    private var maxUtilization: Double? {
        guard let usage = usage else { return nil }
        return max(usage.primaryUtilization, usage.secondaryUtilization ?? 0)
    }

    var body: some View {
        HStack(spacing: BurnrateTheme.spacingSM) {
            // Provider icon
            BrandIcon(providerId: info.id, size: 10)
                .foregroundStyle(info.color)
                .frame(width: 16, height: 16)

            // Provider name
            Text(info.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(BurnrateTheme.textSecondary)
                .frame(width: 62, alignment: .leading)

            // Usage indicator
            if let util = maxUtilization {
                // Mini progress bar
                MiniProgressBar(value: util, color: info.color)

                Text("\(Int(util.rounded()))%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(statusColor(for: util))
                    .frame(width: 32, alignment: .trailing)
            } else if installed && tracked {
                Spacer()
                Text("No data")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(BurnrateTheme.textTertiary)
            } else if installed && !tracked {
                Spacer()
                Text("Coming soon")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(info.color.opacity(0.6))
            } else {
                Spacer()
                Text("Not found")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(BurnrateTheme.textTertiary.opacity(0.6))
            }
        }
        .padding(.horizontal, BurnrateTheme.spacingSM)
        .padding(.vertical, BurnrateTheme.spacingXS + 1)
    }

    private func statusColor(for value: Double) -> Color {
        if value >= 90 { return BurnrateTheme.statusRed }
        if value >= 70 { return BurnrateTheme.statusOrange }
        return BurnrateTheme.textPrimary
    }
}

// MARK: - Mini Progress Bar

private struct MiniProgressBar: View {
    let value: Double
    let color: Color

    @State private var animatedValue: Double = 0

    private var fillColor: Color {
        if value >= 90 { return BurnrateTheme.statusRed }
        if value >= 70 { return BurnrateTheme.statusOrange }
        return color
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.primary.opacity(0.06))

                RoundedRectangle(cornerRadius: 2)
                    .fill(fillColor)
                    .frame(width: max(0, geometry.size.width * min(animatedValue, 100) / 100))
            }
        }
        .frame(height: 4)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.easeOut(duration: 0.3)) {
                animatedValue = newValue
            }
        }
    }
}

#Preview {
    UsageSummaryView(
        providerInfos: [
            ProviderInfo(id: "claude", name: "Claude", icon: "message.fill", brandColor: 0xDA7756, unavailableMessage: ""),
            ProviderInfo(id: "codex", name: "Codex", icon: "terminal.fill", brandColor: 0x10A37F, unavailableMessage: ""),
            ProviderInfo(id: "kimi", name: "Kimi K2.5", icon: "sparkles", brandColor: 0x6366F1, unavailableMessage: ""),
            ProviderInfo(id: "gemini", name: "Gemini", icon: "wand.and.stars", brandColor: 0x4285F4, unavailableMessage: ""),
        ],
        providerUsages: [
            "claude": ProviderUsage(primaryUtilization: 35, primaryLabel: "5h", primaryResetsAt: nil, secondaryUtilization: 72, secondaryLabel: "7d", secondaryResetsAt: nil, extraInfo: nil),
            "codex": ProviderUsage(primaryUtilization: 25, primaryLabel: "5h", primaryResetsAt: nil, secondaryUtilization: 45, secondaryLabel: "Weekly", secondaryResetsAt: nil, extraInfo: nil),
        ],
        isInstalled: { id in id == "claude" || id == "codex" || id == "kimi" },
        hasTracking: { id in id == "claude" || id == "codex" }
    )
    .padding()
    .frame(width: 320)
    .background(Color(NSColor.windowBackgroundColor))
}
