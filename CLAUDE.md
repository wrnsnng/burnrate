# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Burnrate is a macOS menubar application that displays Claude Code usage statistics. Built by Common Tools Co.

Features:
- Current session token usage
- API usage limits (5-hour, 7-day, Opus) with visual progress bars
- Recent sessions with quick-resume capability
- Usage alerts at 80% and 90% thresholds
- Analytics dashboard with historical trends
- Customizable menubar display
- Settings window with tabbed interface

## Commands

```bash
# Build and run
swift build
swift run

# Build release
swift build -c release

# Create .app bundle
mkdir -p "Burnrate.app/Contents/MacOS"
cp .build/release/Burnrate "Burnrate.app/Contents/MacOS/"
cp Resources/Info.plist "Burnrate.app/Contents/"
zip -r "Burnrate.zip" "Burnrate.app"
```

## Architecture

```
burnrate/
├── Package.swift
├── Resources/
│   └── Info.plist
└── Sources/Burnrate/
    ├── BurnrateApp.swift           # Entry point, starts NSApplication
    ├── AppDelegate.swift           # NSStatusItem + NSPopover + window management
    ├── ContentView.swift           # Main popover view with ScrollView
    ├── UsageViewModel.swift        # @Observable state, data fetching, refresh timer
    │
    ├── Models/
    │   ├── SessionInfo.swift       # Session and CurrentSession structs
    │   ├── UsageLimits.swift       # API usage data
    │   └── AccountInfo.swift       # Account settings
    │
    ├── Services/
    │   ├── SessionParser.swift     # Streaming JSONL parser for session files
    │   ├── AccountParser.swift     # Reads ~/.claude.json
    │   ├── UsageAPIClient.swift    # Fetches from Anthropic API (actor)
    │   ├── KeychainService.swift   # Reads OAuth token via security CLI
    │   ├── NotificationService.swift  # macOS notifications for usage alerts
    │   ├── AnalyticsStore.swift    # Persistent storage for usage history
    │   └── SettingsService.swift   # User preferences (menubar display, etc.)
    │
    └── Views/
        ├── CurrentSessionView.swift
        ├── UsageLimitsView.swift
        ├── ExtraUsageView.swift
        ├── RecentSessionsView.swift
        ├── AnalyticsView.swift     # Charts using SwiftUI Charts
        ├── SettingsView.swift      # Tabbed settings (General, Alerts, About)
        ├── AlertSettingsView.swift
        └── ProgressBarView.swift
```

**Key patterns:**
- `UsageViewModel` uses `@Observable` for SwiftUI state management
- `UsageAPIClient` is an `actor` for thread-safe API caching
- `SessionParser` uses streaming `FileHandle` reads to handle large session files (>10MB)
- `KeychainService` uses `/usr/bin/security` CLI for reliable keychain access
- `AnalyticsStore` is an `actor` that persists data to `~/.burnrate/analytics.json`
- `NotificationService` guards against unbundled execution for `UNUserNotificationCenter`

## Data Sources

1. **Session files**: `~/.claude/projects/<encoded-path>/*.jsonl`
   - Path encoding: `/` → `-`, `/_` → `--`
   - JSONL with `user`, `assistant`, `summary` entry types

2. **Account config**: `~/.claude.json`
   - `oauthAccount.hasExtraUsageEnabled`
   - `oauthAccount.organizationBillingType`

3. **Usage API**: `https://api.anthropic.com/api/oauth/usage`
   - OAuth token from Keychain service `Claude Code-credentials`
   - Returns `five_hour`, `seven_day`, `seven_day_opus` utilization

4. **Analytics storage**: `~/.burnrate/analytics.json`
   - Hourly usage snapshots (kept 30 days)
   - Daily stats: tokens, sessions, estimated cost (kept 1 year)

## Key Implementation Details

- Session files use streaming reads to handle multi-GB files without loading into memory
- OAuth tokens retrieved via `security find-generic-password` CLI command
- API responses cached for 30 seconds
- Auto-refresh every 60 seconds
- Clicking recent session opens Terminal with `claude --resume <session_id>`
- Notifications only work when running as bundled .app (not `swift run`)
- Menubar display preference stored in UserDefaults

## Windows

The app manages three window types:
1. **Popover** - Main UI, attached to menubar icon
2. **Analytics Window** - Separate window for charts and stats
3. **Settings Window** - Tabbed preferences (General, Alerts, About)
