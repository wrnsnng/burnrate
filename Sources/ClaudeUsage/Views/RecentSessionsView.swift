import SwiftUI

struct RecentSessionsView: View {
    let sessions: [SessionInfo]
    let onSessionTap: (SessionInfo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Recent Sessions", systemImage: "clock.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            if sessions.isEmpty {
                Text("No recent sessions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            } else {
                VStack(spacing: 2) {
                    ForEach(sessions) { session in
                        SessionRowView(session: session)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSessionTap(session)
                            }
                    }
                }
            }
        }
    }
}

struct SessionRowView: View {
    let session: SessionInfo

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "play.circle.fill")
                .foregroundStyle(Color.accentColor)
                .font(.system(size: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text(session.slug)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 8) {
                    Text(session.projectName)
                    Text(formatRelativeTime(session.timestamp))
                    if session.totalTokens > 0 {
                        Text(formatTokens(session.totalTokens))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))

        if seconds < 60 {
            return "now"
        } else if seconds < 3600 {
            return "\(seconds / 60)m"
        } else if seconds < 86400 {
            return "\(seconds / 3600)h"
        } else if seconds < 604800 {
            return "\(seconds / 86400)d"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
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

#Preview {
    RecentSessionsView(
        sessions: [
            SessionInfo(
                id: "1",
                slug: "Implement SwiftUI menubar",
                projectPath: "/Users/test/claude-usage",
                encodedProject: "-Users-test-claude-usage",
                timestamp: Date().addingTimeInterval(-3600),
                messageCount: 15,
                totalTokens: 45000,
                summary: nil,
                model: "claude-3-5-sonnet"
            ),
            SessionInfo(
                id: "2",
                slug: "Fix authentication bug",
                projectPath: "/Users/test/other-project",
                encodedProject: "-Users-test-other-project",
                timestamp: Date().addingTimeInterval(-86400),
                messageCount: 8,
                totalTokens: 12000,
                summary: nil,
                model: "claude-3-5-sonnet"
            )
        ],
        onSessionTap: { _ in }
    )
    .padding()
    .frame(width: 280)
}
