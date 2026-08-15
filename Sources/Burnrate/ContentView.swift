import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: UsageViewModel
    let onQuit: () -> Void
    let onShowAnalytics: () -> Void
    let onShowSettings: () -> Void

    @State private var isRefreshing = false
    @State private var expandedProviders: Set<String>

    init(viewModel: UsageViewModel, onQuit: @escaping () -> Void, onShowAnalytics: @escaping () -> Void, onShowSettings: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onQuit = onQuit
        self.onShowAnalytics = onShowAnalytics
        self.onShowSettings = onShowSettings

        // Load persisted expansion state, default to all expanded
        if let saved = UserDefaults.standard.array(forKey: "expandedProviders") as? [String] {
            self._expandedProviders = State(initialValue: Set(saved))
        } else {
            self._expandedProviders = State(initialValue: Set<String>())
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(
                isLoading: viewModel.isLoading,
                onSettings: onShowSettings
            )
            .padding(.horizontal, BurnrateTheme.spacingLG)
            .padding(.top, BurnrateTheme.spacingLG)
            .padding(.bottom, BurnrateTheme.spacingMD)

            // Content
            ScrollView {
                VStack(spacing: BurnrateTheme.spacingMD) {
                    // Error message
                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                    }

                    // Usage summary (quick glance across all LLMs)
                    UsageSummaryView(
                        providerInfos: viewModel.providerInfos,
                        providerUsages: viewModel.providerUsages,
                        isInstalled: { viewModel.providerIsInstalled($0) },
                        hasTracking: { viewModel.providerHasTracking($0) }
                    )

                    // Expandable provider detail sections
                    ForEach(viewModel.providerInfos, id: \.id) { info in
                        ProviderUsageCard(
                            providerInfo: info,
                            usage: viewModel.providerUsages[info.id],
                            isInstalled: viewModel.providerIsInstalled(info.id),
                            hasTracking: viewModel.providerHasTracking(info.id),
                            isExpanded: expandedBinding(for: info.id),
                            extraContent: extraContent(for: info.id)
                        )
                    }

                    // Recent Sessions (Claude)
                    RecentSessionsView(
                        sessions: viewModel.recentSessions,
                        onSessionTap: { session in
                            viewModel.openSession(session)
                        }
                    )
                }
                .padding(.horizontal, BurnrateTheme.spacingLG)
                .padding(.bottom, BurnrateTheme.spacingMD)
            }
            .scrollIndicators(.never)

            // Footer Actions
            FooterActionsView(
                onOpenClaude: { viewModel.openClaude() },
                onRefresh: {
                    withAnimation(BurnrateTheme.springSnappy) {
                        isRefreshing = true
                    }
                    viewModel.refresh()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(BurnrateTheme.springSnappy) {
                            isRefreshing = false
                        }
                    }
                },
                onAnalytics: onShowAnalytics,
                onQuit: onQuit,
                isRefreshing: isRefreshing
            )
            .padding(BurnrateTheme.spacingLG)
            .background(
                Rectangle()
                    .fill(BurnrateTheme.surfaceSecondary)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(BurnrateTheme.cardBorder)
                            .frame(height: 1)
                    }
            )
        }
        .frame(width: 340)
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: expandedProviders) { _, newValue in
            UserDefaults.standard.set(Array(newValue), forKey: "expandedProviders")
        }
    }

    private func expandedBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: { expandedProviders.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    expandedProviders.insert(id)
                } else {
                    expandedProviders.remove(id)
                }
            }
        )
    }

    /// Provides extra inline content for specific providers
    private func extraContent(for providerId: String) -> AnyView? {
        switch providerId {
        case "claude":
            var views: [AnyView] = []

            // Active session card
            views.append(AnyView(
                CurrentSessionView(session: viewModel.currentSession)
            ))

            // Opus usage bar if active
            if let limits = viewModel.usageLimits,
               (limits.opusUtilization > 0 || limits.opusResetsAt != nil) {
                views.append(AnyView(
                    ProgressBarView(
                        value: limits.opusUtilization,
                        label: "Opus",
                        resetsAt: limits.opusResetsAt
                    )
                ))
            }

            // Extra usage status
            views.append(AnyView(
                ExtraUsageView(accountInfo: viewModel.accountInfo)
            ))

            return AnyView(
                VStack(spacing: BurnrateTheme.spacingXS) {
                    ForEach(0..<views.count, id: \.self) { i in
                        views[i]
                    }
                }
            )

        default:
            return nil
        }
    }
}

// MARK: - Header

struct HeaderView: View {
    let isLoading: Bool
    let onSettings: () -> Void

    @State private var flameOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: BurnrateTheme.spacingMD) {
            // Logo
            HStack(spacing: BurnrateTheme.spacingSM) {
                ZStack {
                    // Glow effect
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(BurnrateTheme.accentGradient)
                        .blur(radius: 6)
                        .opacity(0.5)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(BurnrateTheme.accentGradient)
                        .offset(y: flameOffset)
                }
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true)
                    ) {
                        flameOffset = -1.5
                    }
                }

                Text("Burnrate")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(BurnrateTheme.textPrimary)
            }

            Spacer()

            // Loading indicator
            if isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 20, height: 20)
            }

            // Settings button
            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
            }
            .buttonStyle(IconButtonStyle())
        }
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: BurnrateTheme.spacingSM) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(BurnrateTheme.statusOrange)

            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(BurnrateTheme.textSecondary)

            Spacer()
        }
        .padding(BurnrateTheme.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                .fill(BurnrateTheme.statusOrange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                        .strokeBorder(BurnrateTheme.statusOrange.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Footer Actions

struct FooterActionsView: View {
    let onOpenClaude: () -> Void
    let onRefresh: () -> Void
    let onAnalytics: () -> Void
    let onQuit: () -> Void
    let isRefreshing: Bool

    var body: some View {
        HStack(spacing: BurnrateTheme.spacingSM) {
            Button(action: onOpenClaude) {
                Label("Claude", systemImage: "terminal.fill")
            }
            .buttonStyle(ActionButtonStyle())

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(
                        isRefreshing ? .linear(duration: 0.5) : .default,
                        value: isRefreshing
                    )
            }
            .buttonStyle(ActionButtonStyle())

            Button(action: onAnalytics) {
                Label("Analytics", systemImage: "chart.xyaxis.line")
            }
            .buttonStyle(ActionButtonStyle())

            Spacer()

            Button(action: onQuit) {
                Image(systemName: "power")
            }
            .buttonStyle(ActionButtonStyle(isDestructive: true))
        }
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
            vm.codexUsageLimits = CodexUsageLimits(
                fiveHourUtilization: 25,
                fiveHourResetsAt: Date().addingTimeInterval(7200),
                weeklyUtilization: 45,
                weeklyResetsAt: Date().addingTimeInterval(86400 * 5),
                inputTokens: 10000,
                outputTokens: 5000,
                reasoningTokens: 2000
            )
            vm.providerUsages["claude"] = ProviderUsage(
                primaryUtilization: 35, primaryLabel: "5-hour",
                primaryResetsAt: Date().addingTimeInterval(3600),
                secondaryUtilization: 72, secondaryLabel: "7-day",
                secondaryResetsAt: Date().addingTimeInterval(86400 * 3),
                extraInfo: nil
            )
            vm.providerUsages["codex"] = ProviderUsage(
                primaryUtilization: 25, primaryLabel: "5-hour",
                primaryResetsAt: Date().addingTimeInterval(7200),
                secondaryUtilization: 45, secondaryLabel: "Weekly",
                secondaryResetsAt: Date().addingTimeInterval(86400 * 5),
                extraInfo: nil
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
