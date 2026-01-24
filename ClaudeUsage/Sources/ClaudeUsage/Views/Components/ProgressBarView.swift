import SwiftUI

struct ProgressBarView: View {
    let value: Double
    let label: String
    let resetsAt: Date?

    private var percentage: Int {
        Int(value.rounded())
    }

    private var progressColor: Color {
        if value >= 90 {
            return .red
        } else if value >= 70 {
            return .orange
        }
        return .accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(percentage)%")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: max(0, geometry.size.width * min(value, 100) / 100), height: 8)
                }
            }
            .frame(height: 8)

            if let resetsAt = resetsAt {
                Text("Resets \(formatTimeRemaining(resetsAt))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
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
    VStack(spacing: 20) {
        ProgressBarView(value: 35, label: "5-Hour", resetsAt: Date().addingTimeInterval(3600))
        ProgressBarView(value: 72, label: "7-Day", resetsAt: Date().addingTimeInterval(86400))
        ProgressBarView(value: 95, label: "Opus", resetsAt: nil)
    }
    .padding()
    .frame(width: 280)
}
