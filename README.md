<p align="center">
  <img src="Resources/icon.png" alt="Burnrate" width="128" height="128">
</p>

# Burnrate

A macOS menubar app that displays your Claude Code usage statistics in real-time.

Built by **Common Tools Co.**

## Features

- **Real-time Usage Tracking**: Monitor your 5-hour, 7-day, and Opus utilization with visual progress bars
- **Current Session Info**: See token count and message count for your active session
- **Recent Sessions**: Quick access to your 8 most recent sessions with one-click resume
- **Usage Alerts**: Get notified when usage crosses 80% or 90% thresholds
- **Analytics Dashboard**: View historical usage trends with charts (24h, 7d, 30d)
- **Customizable Menubar**: Choose what to display (5-hour %, 7-day %, both, or icon only)
- **Settings Window**: Tabbed interface for General, Alerts, and About settings
- **Auto-refresh**: Data updates every 60 seconds automatically

## Prerequisites

- macOS 14.0 (Sonoma) or later
- [Claude Code](https://claude.ai/code) installed and logged in (the app reads your OAuth token from Claude Code's keychain)

## Installation

### Option 1: Download Release (Recommended)

Download the latest `Burnrate.zip` from [Releases](https://github.com/wrnsnng/claude-usage/releases), unzip, and move to Applications.

### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/wrnsnng/claude-usage.git
cd claude-usage

# Build and run
swift build
swift run
```

To create a distributable .app bundle:

```bash
# Build release
swift build -c release

# Create app bundle
mkdir -p "Burnrate.app/Contents/MacOS"
cp .build/release/Burnrate "Burnrate.app/Contents/MacOS/"
cp Resources/Info.plist "Burnrate.app/Contents/"

# Zip for distribution
zip -r "Burnrate.zip" "Burnrate.app"
```

## Project Structure

```
claude-usage/
├── Package.swift
├── Resources/
│   └── Info.plist                  # App bundle config
├── Sources/Burnrate/
│   ├── BurnrateApp.swift          # App entry point
│   ├── AppDelegate.swift           # Menubar & window management
│   ├── ContentView.swift           # Main popover UI
│   ├── UsageViewModel.swift        # Data fetching & state
│   ├── Models/
│   │   ├── SessionInfo.swift       # Session data
│   │   ├── UsageLimits.swift       # API usage data
│   │   └── AccountInfo.swift       # Account settings
│   ├── Services/
│   │   ├── SessionParser.swift     # Streaming JSONL parser
│   │   ├── AccountParser.swift     # Reads ~/.claude.json
│   │   ├── UsageAPIClient.swift    # Anthropic API client
│   │   ├── KeychainService.swift   # OAuth token access
│   │   ├── NotificationService.swift  # Usage alerts
│   │   ├── AnalyticsStore.swift    # Historical data storage
│   │   └── SettingsService.swift   # User preferences
│   └── Views/
│       ├── CurrentSessionView.swift
│       ├── UsageLimitsView.swift
│       ├── ExtraUsageView.swift
│       ├── RecentSessionsView.swift
│       ├── AnalyticsView.swift     # Charts & trends
│       ├── SettingsView.swift      # Tabbed settings
│       ├── AlertSettingsView.swift
│       └── ProgressBarView.swift
├── CLAUDE.md
└── README.md
```

## How It Works

The app reads data from three sources:

1. **Session Files** (`~/.claude/projects/`): JSONL files containing your conversation history with token usage
2. **Account Config** (`~/.claude.json`): Your account settings including extra usage status
3. **Anthropic API**: Real-time usage limits fetched using your OAuth token from the macOS Keychain

Analytics data is stored locally in `~/.claude-usage/analytics.json`.

## Development

Key files:

- `UsageViewModel.swift` - Central state management with `@Observable`
- `Services/SessionParser.swift` - Streaming JSONL parser (handles large files efficiently)
- `Services/KeychainService.swift` - Reads OAuth token via `security` CLI
- `Services/UsageAPIClient.swift` - Fetches usage from Anthropic API
- `Services/AnalyticsStore.swift` - Persists usage snapshots and daily stats
- `Services/NotificationService.swift` - Handles macOS notifications for alerts

To modify the UI, edit files in `Views/`. The app uses standard SwiftUI components.

### Debugging

Run with debug output:
```bash
swift build && .build/debug/Burnrate
```

Logs are printed to stderr with `[DEBUG]` prefix.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

## Known Issues

- Requires Claude Code to be installed and logged in for OAuth token access

## License

MIT License - feel free to use and modify as needed.

## Acknowledgments

Built with [Claude Code](https://claude.ai/code) assistance.
