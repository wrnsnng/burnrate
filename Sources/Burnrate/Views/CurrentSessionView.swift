import SwiftUI

struct CurrentSessionView: View {
    let session: CurrentSession?
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: BurnrateTheme.spacingMD) {
            SectionHeader(
                title: "Active session",
                icon: "bolt.fill",
                iconColor: BurnrateTheme.statusOrange
            )

            if let session = session {
                SessionCard(session: session, onTap: onTap)
            } else {
                NoSessionView()
            }
        }
    }
}

// MARK: - Session Card

struct SessionCard: View {
    let session: CurrentSession
    var onTap: (() -> Void)? = nil
    @State private var isHovered = false

    private var isActive: Bool {
        guard let lastModified = session.lastModified else { return false }
        return Date().timeIntervalSince(lastModified) < 30
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BurnrateTheme.spacingMD) {
            // Session title + status badge
            HStack(alignment: .top) {
                Text(session.slug)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BurnrateTheme.textPrimary)
                    .lineLimit(2)

                Spacer()

                if isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(BurnrateTheme.statusGreen)
                            .frame(width: 6, height: 6)
                        Text("Active")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(BurnrateTheme.statusGreen)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(BurnrateTheme.statusGreen.opacity(0.12))
                    )
                }
            }

            // Stats row
            HStack(spacing: BurnrateTheme.spacingLG) {
                StatPill(
                    icon: "number",
                    value: formatTokens(session.totalTokens),
                    label: "tokens"
                )

                StatPill(
                    icon: "bubble.left.and.bubble.right.fill",
                    value: "\(session.messageCount)",
                    label: "messages"
                )
            }

            // Duration + last active
            HStack(spacing: BurnrateTheme.spacingXS) {
                Image(systemName: "clock")
                    .font(.system(size: 10, weight: .medium))

                if isActive {
                    Text("Started \(formatRelativeTime(session.startTime))")
                } else if let lastModified = session.lastModified {
                    Text("Last active \(formatRelativeTime(lastModified))")
                } else {
                    Text("Started \(formatRelativeTime(session.startTime))")
                }
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(BurnrateTheme.textTertiary)

            // Hover hint
            if isHovered && onTap != nil {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 10, weight: .medium))
                    Text("Open in terminal")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color.accentColor)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(BurnrateTheme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: BurnrateTheme.radiusMD)
                .fill(isHovered && onTap != nil ? BurnrateTheme.cardBackgroundHover : BurnrateTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: BurnrateTheme.radiusMD)
                        .strokeBorder(BurnrateTheme.cardBorder, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
        .onHover { hovering in
            withAnimation(BurnrateTheme.easeOut) {
                isHovered = hovering
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

// MARK: - Stat Pill

struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: BurnrateTheme.spacingXS) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(BurnrateTheme.textTertiary)

            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(BurnrateTheme.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(BurnrateTheme.textTertiary)
        }
    }
}

// MARK: - No Session View

struct NoSessionView: View {
    var body: some View {
        HStack(spacing: BurnrateTheme.spacingMD) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(BurnrateTheme.textTertiary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                        .fill(BurnrateTheme.cardBackground)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("No active session")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BurnrateTheme.textSecondary)

                Text("Run 'claude' to start coding")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(BurnrateTheme.textTertiary)
            }

            Spacer()
        }
        .padding(BurnrateTheme.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: BurnrateTheme.radiusMD)
                .fill(BurnrateTheme.cardBackground)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        CurrentSessionView(
            session: CurrentSession(
                sessionId: "abc123",
                slug: "Implement SwiftUI menubar app with custom theming",
                projectPath: "/Users/test/project",
                startTime: Date().addingTimeInterval(-3600),
                lastModified: Date().addingTimeInterval(-10),
                inputTokens: 15000,
                outputTokens: 8000,
                cacheReadTokens: 5000,
                cacheCreationTokens: 2000,
                messageCount: 12
            ),
            onTap: {}
        )

        CurrentSessionView(session: nil)
    }
    .padding()
    .frame(width: 320)
    .background(Color(NSColor.windowBackgroundColor))
}
