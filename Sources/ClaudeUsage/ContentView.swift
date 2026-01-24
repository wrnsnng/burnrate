import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: UsageViewModel
    let onQuit: () -> Void
    let onShowAnalytics: () -> Void
    let onShowSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (fixed)
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("Claude Usage")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
                Button(action: onShowSettings) {
                    Image(systemName: "gear")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 12)

            Divider()

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Error message if present
                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    // Current Session
                    CurrentSessionView(session: viewModel.currentSession)

                    Divider()

                    // Usage Limits
                    UsageLimitsView(
                        limits: viewModel.usageLimits,
                        isTokenExpired: viewModel.isTokenExpired
                    )

                    Divider()

                    // Extra Usage
                    ExtraUsageView(accountInfo: viewModel.accountInfo)

                    Divider()

                    // Recent Sessions
                    RecentSessionsView(
                        sessions: viewModel.recentSessions,
                        onSessionTap: { session in
                            viewModel.openSession(session)
                        }
                    )
                }
                .padding(.vertical, 12)
                .padding(.trailing, 4)
            }
            .scrollIndicators(.never)

            Divider()

            // Actions (fixed at bottom)
            HStack(spacing: 12) {
                Button(action: { viewModel.openClaude() }) {
                    Label("Open Claude", systemImage: "terminal")
                }

                Button(action: { viewModel.refresh() }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }

                Button(action: onShowAnalytics) {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }

                Spacer()

                Button(action: onQuit) {
                    Label("Quit", systemImage: "power")
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .font(.subheadline)
            .padding(.top, 12)
        }
        .padding(16)
        .frame(width: 320)
    }
}

#Preview {
    ContentView(
        viewModel: {
            let vm = UsageViewModel()
            vm.currentSession = CurrentSession(
                sessionId: "abc123",
                slug: "Build SwiftUI app",
                projectPath: "/Users/test/project",
                startTime: Date().addingTimeInterval(-3600),
                inputTokens: 15000,
                outputTokens: 8000,
                cacheReadTokens: 0,
                cacheCreationTokens: 0,
                messageCount: 12
            )
            vm.usageLimits = UsageLimits(
                fiveHourUtilization: 35,
                fiveHourResetsAt: Date().addingTimeInterval(3600),
                sevenDayUtilization: 72,
                sevenDayResetsAt: Date().addingTimeInterval(86400 * 3),
                opusUtilization: 0,
                opusResetsAt: nil
            )
            vm.accountInfo = AccountInfo(hasExtraUsageEnabled: true, billingType: "pro", email: nil)
            vm.isTokenExpired = false
            return vm
        }(),
        onQuit: {},
        onShowAnalytics: {},
        onShowSettings: {}
    )
}
