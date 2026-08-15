import SwiftUI
import WidgetKit

// MARK: - Color Palette

private enum WidgetColors {
    static let green  = Color(red: 0.22, green: 0.78, blue: 0.45)
    static let orange = Color(red: 0.96, green: 0.65, blue: 0.14)
    static let red    = Color(red: 0.94, green: 0.27, blue: 0.27)

    static func barColor(for utilization: Double) -> Color {
        if utilization >= 90 { return red }
        if utilization >= 70 { return orange }
        return green
    }
}

// MARK: - Relative Time Formatting

private func relativeTimeString(from date: Date?) -> String {
    guard let date = date else { return "" }
    let seconds = Date.now.timeIntervalSince(date)
    if seconds < 60 { return "Updated just now" }
    let minutes = Int(seconds / 60)
    if minutes == 1 { return "Updated 1 min ago" }
    if minutes < 60 { return "Updated \(minutes) min ago" }
    let hours = minutes / 60
    if hours == 1 { return "Updated 1 hr ago" }
    return "Updated \(hours) hrs ago"
}

private func resetTimeString(from date: Date?) -> String? {
    guard let date = date else { return nil }
    let remaining = date.timeIntervalSince(.now)
    if remaining <= 0 { return "Resetting..." }

    let days = Int(remaining / 86400)
    let hours = Int(remaining.truncatingRemainder(dividingBy: 86400) / 3600)
    let minutes = Int(remaining.truncatingRemainder(dividingBy: 3600) / 60)

    if days > 0 { return "Resets in \(days)d \(hours)h" }
    if hours > 0 { return "Resets in \(hours)h \(minutes)m" }
    return "Resets in \(minutes)m"
}

// MARK: - Entry View Router

struct BurnrateWidgetEntryView: View {
    var entry: UsageEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - System Small

private struct SmallWidgetView: View {
    let entry: UsageEntry

    private var topProvider: ProviderData? {
        entry.providers.max(by: { $0.primaryUtilization < $1.primaryUtilization })
    }

    var body: some View {
        if entry.providers.isEmpty {
            emptyState
        } else if let provider = topProvider {
            providerGauge(provider)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(.secondary)

            Text("No Data")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Text("Open Burnrate to sync")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func providerGauge(_ provider: ProviderData) -> some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)

            // Circular gauge
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: min(provider.primaryUtilization / 100, 1.0))
                    .stroke(
                        WidgetColors.barColor(for: provider.primaryUtilization),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 1) {
                    Text("\(Int(provider.primaryUtilization.rounded()))%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(provider.primaryLabel)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 72, height: 72)

            // Provider name
            Text(provider.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            // Updated timestamp
            Text(relativeTimeString(from: entry.lastUpdated))
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - System Medium

private struct MediumWidgetView: View {
    let entry: UsageEntry

    /// Show at most 2 providers, sorted by highest utilization first.
    private var displayProviders: [ProviderData] {
        Array(
            entry.providers
                .sorted { $0.primaryUtilization > $1.primaryUtilization }
                .prefix(2)
        )
    }

    var body: some View {
        if entry.providers.isEmpty {
            emptyState
        } else {
            providerColumns
        }
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("No Usage Data")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Open Burnrate on your Mac to sync usage data.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var providerColumns: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ForEach(displayProviders) { provider in
                    ProviderColumn(provider: provider)
                }
            }

            Spacer(minLength: 0)

            // Footer
            HStack {
                Spacer()
                Text(relativeTimeString(from: entry.lastUpdated))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A single provider column used in the medium widget.
private struct ProviderColumn: View {
    let provider: ProviderData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Provider name
            Text(provider.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            // Primary bar
            UsageBar(
                label: provider.primaryLabel,
                utilization: provider.primaryUtilization
            )

            // Secondary bar (if available)
            if let secondaryUtil = provider.secondaryUtilization,
               let secondaryLabel = provider.secondaryLabel {
                UsageBar(
                    label: secondaryLabel,
                    utilization: secondaryUtil
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - System Large

private struct LargeWidgetView: View {
    let entry: UsageEntry

    var body: some View {
        if entry.providers.isEmpty {
            emptyState
        } else {
            providerList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.secondary)

            Text("No Usage Data")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)

            Text("Open Burnrate on your Mac to sync your usage data to the cloud.")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var providerList: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Burnrate Usage")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            // Provider rows
            VStack(spacing: 10) {
                ForEach(entry.providers) { provider in
                    ProviderRow(provider: provider)

                    if provider.id != entry.providers.last?.id {
                        Divider().opacity(0.3)
                    }
                }
            }

            Spacer(minLength: 0)

            // Footer
            HStack {
                Spacer()
                Text(relativeTimeString(from: entry.lastUpdated))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A full provider row used in the large widget.
private struct ProviderRow: View {
    let provider: ProviderData

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Provider name
            Text(provider.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            // Primary bar
            UsageBar(
                label: provider.primaryLabel,
                utilization: provider.primaryUtilization
            )

            // Secondary bar
            if let secondaryUtil = provider.secondaryUtilization,
               let secondaryLabel = provider.secondaryLabel {
                UsageBar(
                    label: secondaryLabel,
                    utilization: secondaryUtil
                )
            }

            // Reset time
            if let resetStr = resetTimeString(from: provider.primaryResetsAt) {
                Text(resetStr)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Shared Components

/// A compact horizontal progress bar with label and percentage.
private struct UsageBar: View {
    let label: String
    let utilization: Double

    private var percentage: Int {
        Int(utilization.rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(percentage)%")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(WidgetColors.barColor(for: utilization))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.primary.opacity(0.08))

                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(WidgetColors.barColor(for: utilization))
                        .frame(width: max(0, geometry.size.width * min(CGFloat(utilization) / 100, 1.0)))
                }
            }
            .frame(height: 5)
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    BurnrateMainWidget()
} timeline: {
    UsageEntry.placeholder
    UsageEntry(
        date: .now,
        providers: [
            ProviderData(
                id: "claude",
                name: "Claude",
                primaryUtilization: 87,
                primaryLabel: "5-hour",
                primaryResetsAt: Date().addingTimeInterval(1800),
                secondaryUtilization: 45,
                secondaryLabel: "7-day",
                secondaryResetsAt: Date().addingTimeInterval(86400)
            )
        ],
        lastUpdated: Date().addingTimeInterval(-300),
        isPlaceholder: false
    )
}

#Preview("Medium", as: .systemMedium) {
    BurnrateMainWidget()
} timeline: {
    UsageEntry.placeholder
    UsageEntry(
        date: .now,
        providers: [
            ProviderData(
                id: "claude",
                name: "Claude",
                primaryUtilization: 72,
                primaryLabel: "5-hour",
                primaryResetsAt: Date().addingTimeInterval(3600),
                secondaryUtilization: 34,
                secondaryLabel: "7-day",
                secondaryResetsAt: nil
            ),
            ProviderData(
                id: "codex",
                name: "Codex",
                primaryUtilization: 91,
                primaryLabel: "Daily",
                primaryResetsAt: Date().addingTimeInterval(7200),
                secondaryUtilization: nil,
                secondaryLabel: nil,
                secondaryResetsAt: nil
            ),
        ],
        lastUpdated: Date().addingTimeInterval(-120),
        isPlaceholder: false
    )
}

#Preview("Large", as: .systemLarge) {
    BurnrateMainWidget()
} timeline: {
    UsageEntry.placeholder
    UsageEntry(
        date: .now,
        providers: [
            ProviderData(
                id: "claude",
                name: "Claude",
                primaryUtilization: 55,
                primaryLabel: "5-hour",
                primaryResetsAt: Date().addingTimeInterval(3600),
                secondaryUtilization: 28,
                secondaryLabel: "7-day",
                secondaryResetsAt: Date().addingTimeInterval(172800)
            ),
            ProviderData(
                id: "codex",
                name: "Codex",
                primaryUtilization: 82,
                primaryLabel: "Daily",
                primaryResetsAt: Date().addingTimeInterval(5400),
                secondaryUtilization: nil,
                secondaryLabel: nil,
                secondaryResetsAt: nil
            ),
            ProviderData(
                id: "gemini",
                name: "Gemini",
                primaryUtilization: 15,
                primaryLabel: "Usage",
                primaryResetsAt: Date().addingTimeInterval(14400),
                secondaryUtilization: nil,
                secondaryLabel: nil,
                secondaryResetsAt: nil
            ),
        ],
        lastUpdated: Date().addingTimeInterval(-600),
        isPlaceholder: false
    )
}
