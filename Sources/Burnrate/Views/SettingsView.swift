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
        .padding(.top, BurnrateTheme.spacingMD)
        .frame(minWidth: 400, maxWidth: .infinity, minHeight: 480, maxHeight: .infinity)
    }
}

// MARK: - General Tab

struct GeneralSettingsTab: View {
    @Bindable var settingsService: SettingsService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BurnrateTheme.spacingXL) {
                // Startup section
                SettingsSection(title: "Startup", icon: "power", iconColor: BurnrateTheme.statusGreen) {
                    SettingsToggle(
                        title: "Launch at login",
                        subtitle: settingsService.canUseLaunchAtLogin
                            ? "Start when you log in"
                            : "Requires running as bundled .app",
                        isOn: $settingsService.launchAtStartup,
                        isDisabled: !settingsService.canUseLaunchAtLogin
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
                                    colorScheme: settingsService.menubarColorScheme,
                                    onSelect: { settingsService.menubarDisplay = option }
                                )
                            }
                        }

                        // Chart color scheme picker (only visible when chart is selected)
                        if settingsService.menubarDisplay == .chart {
                            VStack(alignment: .leading, spacing: BurnrateTheme.spacingSM) {
                                Text("Chart color scheme")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(BurnrateTheme.textSecondary)

                                HStack(spacing: BurnrateTheme.spacingSM) {
                                    ForEach(MenubarColorScheme.allCases) { scheme in
                                        ColorSchemeButton(
                                            scheme: scheme,
                                            isSelected: settingsService.menubarColorScheme == scheme,
                                            onSelect: { settingsService.menubarColorScheme = scheme }
                                        )
                                    }
                                }
                            }
                            .padding(.top, BurnrateTheme.spacingXS)
                        }

                        Text("Choose what to display next to the icon in your menubar.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(BurnrateTheme.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(BurnrateTheme.spacingLG)
        }
    }
}

// MARK: - Menubar Option Row

struct MenubarOptionRow: View {
    let option: MenubarDisplay
    let isSelected: Bool
    var colorScheme: MenubarColorScheme = .dynamic
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
                if option == .chart {
                    ChartPreview(colorScheme: colorScheme)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(BurnrateTheme.cardBackground)
                        )
                } else {
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
        case .chart: return nil
        }
    }
}

// MARK: - Chart Preview

struct ChartPreview: View {
    let colorScheme: MenubarColorScheme

    private let fiveHourPreview: Double = 35
    private let sevenDayPreview: Double = 72

    var body: some View {
        VStack(spacing: 2) {
            // Top bar (5-hour)
            RoundedRectangle(cornerRadius: 1)
                .fill(topBarColor)
                .frame(width: 14 * (fiveHourPreview / 100), height: 4)
                .frame(width: 14, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.primary.opacity(0.1))
                )

            // Bottom bar (7-day)
            RoundedRectangle(cornerRadius: 1)
                .fill(bottomBarColor)
                .frame(width: 14 * (sevenDayPreview / 100), height: 4)
                .frame(width: 14, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.primary.opacity(0.1))
                )
        }
    }

    private var topBarColor: Color {
        switch colorScheme {
        case .dynamic:
            return BurnrateTheme.statusGreen
        case .distinct:
            return Color(hex: 0x3B82F6)
        case .monochrome:
            return .primary
        }
    }

    private var bottomBarColor: Color {
        switch colorScheme {
        case .dynamic:
            return BurnrateTheme.statusOrange
        case .distinct:
            return Color(hex: 0xA855F7)
        case .monochrome:
            return .primary
        }
    }
}

// MARK: - Color Scheme Button

struct ColorSchemeButton: View {
    let scheme: MenubarColorScheme
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                // Preview bars
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(topColor)
                        .frame(width: 20, height: 4)

                    RoundedRectangle(cornerRadius: 1)
                        .fill(bottomColor)
                        .frame(width: 20, height: 4)
                }

                Text(scheme.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? BurnrateTheme.textPrimary : BurnrateTheme.textTertiary)
            }
            .padding(.horizontal, BurnrateTheme.spacingSM)
            .padding(.vertical, BurnrateTheme.spacingXS)
            .background(
                RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                    .fill(isSelected ? BurnrateTheme.cardBackgroundHover : (isHovered ? BurnrateTheme.cardBackground : Color.clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: BurnrateTheme.radiusSM)
                            .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(BurnrateTheme.easeOut) {
                isHovered = hovering
            }
        }
    }

    private var topColor: Color {
        switch scheme {
        case .dynamic:
            return BurnrateTheme.statusGreen
        case .distinct:
            return Color(hex: 0x3B82F6)
        case .monochrome:
            return .primary
        }
    }

    private var bottomColor: Color {
        switch scheme {
        case .dynamic:
            return BurnrateTheme.statusOrange
        case .distinct:
            return Color(hex: 0xA855F7)
        case .monochrome:
            return .primary
        }
    }
}

// MARK: - Alerts Tab

struct AlertsSettingsTab: View {
    @Bindable var notificationService: NotificationService

    var body: some View {
        ScrollView {
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
            }
            .padding(BurnrateTheme.spacingLG)
        }
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
    var isDisabled: Bool = false

    var body: some View {
        HStack(spacing: BurnrateTheme.spacingMD) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isDisabled ? BurnrateTheme.textTertiary : BurnrateTheme.textPrimary)

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
                .disabled(isDisabled)
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
            Link(destination: URL(string: "https://github.com/wrnsnng/burnrate")!) {
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
