# Claude Usage

A macOS menubar app that displays your Claude Code usage statistics in real-time.

![Claude Usage Screenshot](screenshot.png)

## Features

- **Real-time Usage Tracking**: Monitor your 5-hour, 7-day, and Opus utilization with visual progress bars
- **Current Session Info**: See token count and message count for your active session
- **Recent Sessions**: Quick access to your 8 most recent sessions with one-click resume
- **Extra Usage Status**: Know if extra usage billing is enabled on your account
- **Auto-refresh**: Data updates every 60 seconds automatically

## Prerequisites

- macOS 14.0 (Sonoma) or later
- [Claude Code](https://claude.ai/code) installed and logged in (the app reads your OAuth token from Claude Code's keychain)

## Installation

### Option 1: Download Release (Recommended)

Download the latest `Claude-Usage.zip` from [Releases](https://github.com/wrnsnng/claude-usage/releases), unzip, and move to Applications.

> **Note**: Since the app is not notarized, you'll need to right-click and select "Open" on first launch.

### Option 2: Build from Source

#### SwiftUI Version (Recommended)

```bash
# Clone the repository
git clone https://github.com/wrnsnng/claude-usage.git
cd claude-usage/ClaudeUsage

# Build and run
swift build
swift run
```

To create a distributable .app bundle:

```bash
cd ClaudeUsage

# Build release
swift build -c release

# Create app bundle
APP_DIR="Claude Usage.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
cp .build/release/ClaudeUsage "$APP_DIR/Contents/MacOS/"

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Claude Usage</string>
    <key>CFBundleIdentifier</key>
    <string>com.claudeusage.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>ClaudeUsage</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Zip for distribution
zip -r "Claude-Usage.zip" "Claude Usage.app"
```

#### Python Version (Legacy)

```bash
cd claude-usage

# Install dependencies
pip3 install -r requirements.txt

# Run
python3 run.py
```

## Project Structure

```
claude-usage/
├── ClaudeUsage/                    # SwiftUI app (recommended)
│   ├── Package.swift
│   └── Sources/ClaudeUsage/
│       ├── ClaudeUsageApp.swift    # App entry point
│       ├── AppDelegate.swift       # Menubar & popover management
│       ├── ContentView.swift       # Main popover UI
│       ├── UsageViewModel.swift    # Data fetching & state
│       ├── Models/                 # Data models
│       ├── Services/               # Data parsers & API client
│       └── Views/                  # UI components
│
├── src/                            # Python app (legacy)
│   ├── main.py                     # App entry point
│   ├── config.py                   # Configuration
│   ├── data/                       # Data layer
│   │   ├── models.py
│   │   ├── session_parser.py
│   │   ├── account_parser.py
│   │   └── usage_api.py
│   └── ui/                         # UI layer
│       ├── menu_builder.py
│       └── formatters.py
│
├── requirements.txt                # Python dependencies
├── setup.py                        # py2app config
└── CLAUDE.md                       # Claude Code guidance
```

## How It Works

The app reads data from three sources:

1. **Session Files** (`~/.claude/projects/`): JSONL files containing your conversation history with token usage
2. **Account Config** (`~/.claude.json`): Your account settings including extra usage status
3. **Anthropic API**: Real-time usage limits fetched using your OAuth token from the macOS Keychain

## Development

### SwiftUI App

The SwiftUI version is the actively maintained implementation. Key files:

- `UsageViewModel.swift` - Central state management with `@Observable`
- `Services/SessionParser.swift` - Streaming JSONL parser (handles large files efficiently)
- `Services/KeychainService.swift` - Reads OAuth token via `security` CLI
- `Services/UsageAPIClient.swift` - Fetches usage from Anthropic API

To modify the UI, edit files in `Views/`. The app uses standard SwiftUI components with a popover-based interface.

### Adding Features

1. Add data models in `Models/`
2. Add data fetching in `Services/`
3. Update `UsageViewModel.swift` to expose new data
4. Create or update views in `Views/`

### Debugging

Run with debug output:
```bash
swift build && .build/debug/ClaudeUsage
```

Logs are printed to stderr with `[DEBUG]` prefix.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

## Known Issues

- App is not signed/notarized - requires right-click > Open on first launch
- Requires Claude Code to be installed and logged in for OAuth token access

## License

MIT License - feel free to use and modify as needed.

## Acknowledgments

Built with [Claude Code](https://claude.ai/code) assistance.
