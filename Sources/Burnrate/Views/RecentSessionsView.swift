import SwiftUI

struct RecentSessionsView: View {
    let sessions: [SessionInfo]
    let onSessionTap: (SessionInfo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BurnrateTheme.spacingMD) {
            SectionHeader(
                title: "Recent",
                icon: "clock.fill",
                iconColor: BurnrateTheme.statusYellow
            )

            if sessions.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    message: "No recent sessions"
                )
            } else {
                VStack(spacing: BurnrateTheme.spacingXS) {
                    ForEach(sessions.prefix(5)) { session in
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
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: BurnrateTheme.spacingMD) {
            // Play icon
            Image(systemName: "play.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(isHovered ? Color.white : BurnrateTheme.textTertiary)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(isHovered ? Color.accentColor : BurnrateTheme.cardBackground)
                )
                .animation(BurnrateTheme.easeOut, value: isHovered)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.slug)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BurnrateTheme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: BurnrateTheme.spacingSM) {
                    Text(session.projectName)
                        .lineLimit(1)

                    Text("·")

                    Text(formatRelativeTime(session.timestamp))

                    if session.totalTokens > 0 {
                        Text("·")
                        Text(formatTokens(session.totalTokens))
                    }
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(BurnrateTheme.textTertiary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(BurnrateTheme.textTertiary)
                .opacity(isHovered ? 1 : 0)
                .animation(BurnrateTheme.easeOut, value: isHovered)
        }
        .padding(.horizontal, BurnrateTheme.spacingMD)
        .padding(.vertical, BurnrateTheme.spacingSM)
        .background(
            RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                .fill(isHovered ? BurnrateTheme.cardBackgroundHover : Color.clear)
        )
        .onHover { hovering in
            withAnimation(BurnrateTheme.easeOut) {
                isHovered = hovering
            }
        }
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
            return String(format: "%.0fK", Double(count) / 1_000)
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
            ),
            SessionInfo(
                id: "3",
                slug: "Add database migrations",
                projectPath: "/Users/test/backend",
                encodedProject: "-Users-test-backend",
                timestamp: Date().addingTimeInterval(-172800),
                messageCount: 23,
                totalTokens: 89000,
                summary: nil,
                model: "claude-3-5-sonnet"
            )
        ],
        onSessionTap: { _ in }
    )
    .padding()
    .frame(width: 320)
    .background(Color(NSColor.windowBackgroundColor))
}
