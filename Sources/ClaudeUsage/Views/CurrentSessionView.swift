import SwiftUI

struct CurrentSessionView: View {
    let session: CurrentSession?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Current Session", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            if let session = session {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.slug)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    HStack(spacing: 12) {
                        Label(formatTokens(session.totalTokens), systemImage: "number")
                        Label("\(session.messageCount) msgs", systemImage: "bubble.left.and.bubble.right")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Text("Started \(formatRelativeTime(session.startTime))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.leading, 4)
            } else {
                Text("No active session")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
        }
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM tokens", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK tokens", Double(count) / 1_000)
        }
        return "\(count) tokens"
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))

        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            return "\(seconds / 60)m ago"
        } else if seconds < 86400 {
            return "\(seconds / 3600)h ago"
        } else {
            return "\(seconds / 86400)d ago"
        }
    }
}

#Preview {
    CurrentSessionView(session: CurrentSession(
        sessionId: "abc123",
        slug: "Implement SwiftUI menubar app",
        projectPath: "/Users/test/project",
        startTime: Date().addingTimeInterval(-3600),
        inputTokens: 15000,
        outputTokens: 8000,
        cacheReadTokens: 5000,
        cacheCreationTokens: 2000,
        messageCount: 12
    ))
    .padding()
    .frame(width: 280)
}
