import SwiftUI
import Charts

struct AnalyticsView: View {
    let snapshots: [UsageSnapshot]
    let todayStats: DailyStats
    let weekStats: (tokens: Int, sessions: Int, cost: Double)

    @State private var selectedTimeRange: TimeRange = .day

    enum TimeRange: String, CaseIterable {
        case day = "24h"
        case week = "7d"
        case month = "30d"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            Divider()

            // Time range picker
            Picker("Time range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)

            // Usage Chart
            if !filteredSnapshots.isEmpty {
                UsageChartView(snapshots: filteredSnapshots)
                    .frame(height: 200)
            } else {
                ContentUnavailableView(
                    "No data yet",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Usage data will appear here after the app runs for a while.")
                )
                .frame(height: 200)
            }

            Divider()

            // Stats
            StatsView(todayStats: todayStats, weekStats: weekStats)

            Spacer()
        }
        .padding(20)
        .frame(width: 400, height: 550)
    }

    private var filteredSnapshots: [UsageSnapshot] {
        let hours: Int
        switch selectedTimeRange {
        case .day: hours = 24
        case .week: hours = 24 * 7
        case .month: hours = 24 * 30
        }

        let cutoff = Date().addingTimeInterval(-Double(hours) * 3600)
        return snapshots.filter { $0.timestamp >= cutoff }
    }
}

struct UsageChartView: View {
    let snapshots: [UsageSnapshot]

    var body: some View {
        Chart {
            ForEach(snapshots) { snapshot in
                LineMark(
                    x: .value("Time", snapshot.timestamp),
                    y: .value("Usage", snapshot.fiveHourUtilization),
                    series: .value("Type", "5-hour")
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 2))

                LineMark(
                    x: .value("Time", snapshot.timestamp),
                    y: .value("Usage", snapshot.sevenDayUtilization),
                    series: .value("Type", "7-day")
                )
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            // Threshold lines
            RuleMark(y: .value("Warning", 80))
                .foregroundStyle(.orange.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

            RuleMark(y: .value("Critical", 90))
                .foregroundStyle(.red.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)%")
                    }
                }
            }
        }
        .chartLegend(position: .bottom)
    }
}

struct StatsView: View {
    let todayStats: DailyStats
    let weekStats: (tokens: Int, sessions: Int, cost: Double)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Today
            VStack(alignment: .leading, spacing: 8) {
                Label("Today", systemImage: "calendar")
                    .font(.headline)

                HStack(spacing: 20) {
                    StatBox(title: "Tokens", value: formatTokens(todayStats.totalTokens))
                    StatBox(title: "Sessions", value: "\(todayStats.sessionCount)")
                    StatBox(title: "Est. Cost", value: String(format: "$%.2f", todayStats.estimatedCost))
                }
            }

            // This Week
            VStack(alignment: .leading, spacing: 8) {
                Label("This week", systemImage: "calendar.badge.clock")
                    .font(.headline)

                HStack(spacing: 20) {
                    StatBox(title: "Tokens", value: formatTokens(weekStats.tokens))
                    StatBox(title: "Sessions", value: "\(weekStats.sessions)")
                    StatBox(title: "Est. Cost", value: String(format: "$%.2f", weekStats.cost))
                }
            }
        }
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(minWidth: 80, alignment: .leading)
    }
}

#Preview {
    AnalyticsView(
        snapshots: [
            UsageSnapshot(timestamp: Date().addingTimeInterval(-3600 * 5), fiveHour: 30, sevenDay: 45),
            UsageSnapshot(timestamp: Date().addingTimeInterval(-3600 * 4), fiveHour: 35, sevenDay: 48),
            UsageSnapshot(timestamp: Date().addingTimeInterval(-3600 * 3), fiveHour: 45, sevenDay: 52),
            UsageSnapshot(timestamp: Date().addingTimeInterval(-3600 * 2), fiveHour: 55, sevenDay: 58),
            UsageSnapshot(timestamp: Date().addingTimeInterval(-3600 * 1), fiveHour: 60, sevenDay: 62),
            UsageSnapshot(timestamp: Date(), fiveHour: 65, sevenDay: 65),
        ],
        todayStats: DailyStats(totalTokens: 150000, sessionCount: 5, estimatedCost: 0.45),
        weekStats: (tokens: 850000, sessions: 28, cost: 2.55)
    )
}
