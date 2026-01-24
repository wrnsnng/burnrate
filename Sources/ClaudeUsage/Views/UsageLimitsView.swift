import SwiftUI

struct UsageLimitsView: View {
    let limits: UsageLimits?
    let isTokenExpired: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Usage Limits", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            if let limits = limits {
                VStack(spacing: 12) {
                    ProgressBarView(
                        value: limits.fiveHourUtilization,
                        label: "5-Hour",
                        resetsAt: limits.fiveHourResetsAt
                    )

                    ProgressBarView(
                        value: limits.sevenDayUtilization,
                        label: "7-Day",
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
                VStack(alignment: .leading, spacing: 4) {
                    Label("Token expired", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text("Run 'claude' to refresh")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 4)
            } else {
                Text("Unable to fetch limits")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
        }
    }
}

#Preview {
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
    .padding()
    .frame(width: 280)
}
