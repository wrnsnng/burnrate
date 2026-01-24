import SwiftUI

struct SettingsView: View {
    @Bindable var settingsService: SettingsService
    @Bindable var notificationService: NotificationService

    var body: some View {
        TabView {
            GeneralSettingsTab(settingsService: settingsService)
                .tabItem {
                    Label("General", systemImage: "gearshape.fill")
                }

            AlertsSettingsTab(notificationService: notificationService)
                .tabItem {
                    Label("Alerts", systemImage: "bell.badge.fill")
                }

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle.fill")
                }
        }
        .frame(minWidth: 400, minHeight: 420)
    }
}

// MARK: - General Tab

struct GeneralSettingsTab: View {
    @Bindable var settingsService: SettingsService

    var body: some View {
        VStack(alignment: .leading, spacing: BurnrateTheme.spacingXL) {
            // Startup section
            SettingsSection(title: "Startup", icon: "power", iconColor: BurnrateTheme.statusGreen) {
                SettingsToggle(
                    title: "Launch at login",
                    subtitle: "Start when you log in",
                    isOn: $settingsService.launchAtStartup
                )
            }

            // Menubar display section
            SettingsSection(title: "Menubar display", icon: "menubar.rectangle") {
                VStack(alignment: .leading, spacing: BurnrateTheme.spacingMD) {
                    // Custom radio-style picker
                    VStack(spacing: BurnrateTheme.spacingSM) {
                        ForEach(MenubarDisplay.allCases) { option in
                            MenubarOptionRow(
                                option: option,
                                isSelected: settingsService.menubarDisplay == option,
                                onSelect: { settingsService.menubarDisplay = option }
                            )
                        }
                    }

                    Text("Choose what to display next to the icon in your menubar.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(BurnrateTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()
        }
        .padding(BurnrateTheme.spacingXL)
    }
}

// MARK: - Menubar Option Row

struct MenubarOptionRow: View {
    let option: MenubarDisplay
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: BurnrateTheme.spacingMD) {
                // Radio indicator
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.accentColor : BurnrateTheme.textTertiary, lineWidth: 1.5)
                        .frame(width: 16, height: 16)

                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(option.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? BurnrateTheme.textPrimary : BurnrateTheme.textSecondary)

                Spacer()

                // Preview of what it looks like
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(BurnrateTheme.statusOrange)

                    if let preview = previewText(for: option) {
                        Text(preview)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(BurnrateTheme.textTertiary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(BurnrateTheme.cardBackground)
                )
            }
            .padding(.horizontal, BurnrateTheme.spacingMD)
            .padding(.vertical, BurnrateTheme.spacingSM)
            .background(
                RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                    .fill(isHovered ? BurnrateTheme.cardBackgroundHover : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(BurnrateTheme.easeOut) {
                isHovered = hovering
            }
        }
    }

    private func previewText(for option: MenubarDisplay) -> String? {
        switch option {
        case .sevenDay: return "72%"
        case .fiveHour: return "35%"
        case .both: return "35|72"
        case .iconOnly: return nil
        }
    }
}

// MARK: - Alerts Tab

struct AlertsSettingsTab: View {
    @Bindable var notificationService: NotificationService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSection(title: "Notifications", icon: "bell.fill", iconColor: BurnrateTheme.statusOrange) {
                VStack(alignment: .leading, spacing: BurnrateTheme.spacingMD) {
                    // Main toggle
                    SettingsToggle(
                        title: "Enable usage alerts",
                        subtitle: "Get notified when approaching limits",
                        isOn: $notificationService.alertsEnabled
                    )

                    if notificationService.alertsEnabled {
                        VStack(spacing: BurnrateTheme.spacingSM) {
                            SettingsToggle(
                                title: "5-hour usage alerts",
                                subtitle: "Alert at 80% and 90%",
                                isOn: $notificationService.fiveHourAlerts,
                                isIndented: true
                            )

                            SettingsToggle(
                                title: "7-day usage alerts",
                                subtitle: "Alert at 80% and 90%",
                                isOn: $notificationService.sevenDayAlerts,
                                isIndented: true
                            )
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(BurnrateTheme.spacingXL)
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    var iconColor: Color = BurnrateTheme.textSecondary
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: BurnrateTheme.spacingMD) {
            // Header
            HStack(spacing: BurnrateTheme.spacingSM) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 18, height: 18)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(iconColor.opacity(0.12))
                    )

                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(BurnrateTheme.textSecondary)
                    .tracking(0.5)
            }

            content
        }
    }
}

// MARK: - Settings Toggle

struct SettingsToggle: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    var isIndented: Bool = false

    var body: some View {
        HStack(spacing: BurnrateTheme.spacingMD) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BurnrateTheme.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(BurnrateTheme.textTertiary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, BurnrateTheme.spacingMD)
        .padding(.vertical, BurnrateTheme.spacingSM)
        .background(
            RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                .fill(BurnrateTheme.cardBackground)
        )
        .padding(.leading, isIndented ? BurnrateTheme.spacingLG : 0)
    }
}

// MARK: - About Tab

struct AboutTab: View {
    @State private var flameOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: BurnrateTheme.spacingLG) {
            Spacer()

            // Logo with glow
            ZStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(BurnrateTheme.accentGradient)
                    .blur(radius: 10)
                    .opacity(0.5)

                Image(systemName: "flame.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(BurnrateTheme.accentGradient)
                    .offset(y: flameOffset)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    flameOffset = -2
                }
            }

            VStack(spacing: 4) {
                Text("Burnrate")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(BurnrateTheme.textPrimary)

                Text("Version 1.0.0")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BurnrateTheme.textTertiary)
            }

            // Divider
            Rectangle()
                .fill(BurnrateTheme.cardBorder)
                .frame(width: 100, height: 1)
                .padding(.vertical, BurnrateTheme.spacingXS)

            // Company
            VStack(spacing: 4) {
                Text("Made by")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(BurnrateTheme.textTertiary)

                Text("Common Tools Co.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BurnrateTheme.textPrimary)
            }

            // GitHub link
            Link(destination: URL(string: "https://github.com/wrnsnng/claude-usage")!) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right.square.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text("View on GitHub")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor.opacity(0.1))
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView(
        settingsService: SettingsService(),
        notificationService: NotificationService()
    )
}
