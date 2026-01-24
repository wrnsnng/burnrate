# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Usage is a macOS menubar application that displays Claude Code usage statistics. It shows:
- Current session token usage
- API usage limits (5-hour, 7-day, Opus) with visual progress bars
- Recent sessions with quick-resume capability
- Extra usage billing status

There are two implementations:
- **SwiftUI version** (`ClaudeUsage/`) - Recommended, native macOS app with popover UI
- **Python version** (`src/`) - Legacy, uses rumps for menubar

## Commands

### SwiftUI Version (Recommended)

```bash
# Build and run
cd ClaudeUsage
swift build
swift run

# Build release
swift build -c release
```

### Python Version (Legacy)

```bash
# Install dependencies
pip3 install -r requirements.txt

# Run
python3 run.py
```

## Architecture

### SwiftUI Version (`ClaudeUsage/`)

```
ClaudeUsage/
├── Package.swift
└── Sources/ClaudeUsage/
    ├── ClaudeUsageApp.swift      # Entry point, starts NSApplication
    ├── AppDelegate.swift          # NSStatusItem + NSPopover management
    ├── ContentView.swift          # Main popover view with ScrollView
    ├── UsageViewModel.swift       # @Observable state, data fetching, refresh timer
    ├── Models/
    │   ├── SessionInfo.swift      # Session and CurrentSession structs
    │   ├── UsageLimits.swift      # API usage data
    │   └── AccountInfo.swift      # Account settings
    ├── Services/
    │   ├── SessionParser.swift    # Streaming JSONL parser for session files
    │   ├── AccountParser.swift    # Reads ~/.claude.json
    │   ├── UsageAPIClient.swift   # Fetches from Anthropic API (actor)
    │   └── KeychainService.swift  # Reads OAuth token via security CLI
    └── Views/
        ├── CurrentSessionView.swift
        ├── UsageLimitsView.swift
        ├── ExtraUsageView.swift
        ├── RecentSessionsView.swift
        └── Components/
            └── ProgressBarView.swift
```

**Key patterns:**
- `UsageViewModel` uses `@Observable` for SwiftUI state management
- `UsageAPIClient` is an `actor` for thread-safe API caching
- `SessionParser` uses streaming `FileHandle` reads to handle large session files (>10MB)
- `KeychainService` uses `/usr/bin/security` CLI (same as Python version) for reliable keychain access

### Python Version (`src/`)

```
src/
├── main.py           # ClaudeUsageApp (rumps.App subclass)
├── config.py         # Paths and constants
├── data/
│   ├── models.py         # Dataclasses
│   ├── session_parser.py # JSONL parser
│   ├── account_parser.py # Config parser
│   └── usage_api.py      # API client
└── ui/
    ├── menu_builder.py   # Menu construction
    └── formatters.py     # Display formatting
```

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

## Key Implementation Details

- Session files use streaming reads to handle multi-GB files without loading into memory
- OAuth tokens retrieved via `security find-generic-password` CLI command
- API responses cached for 30 seconds
- Auto-refresh every 60 seconds
- Clicking recent session opens Terminal with `claude --resume <session_id>`
