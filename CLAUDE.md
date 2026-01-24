# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Usage is a macOS menubar application that displays Claude Code usage statistics. It shows:
- Current session token usage
- API usage limits (5-hour, 7-day, Opus)
- Recent sessions with quick-resume capability
- Extra usage status

## Commands

**Run the app:**
```bash
python run.py
```

**Build standalone macOS app:**
```bash
python setup.py py2app
```

**Install dependencies:**
```bash
pip install -r requirements.txt
```

## Architecture

The app uses `rumps` for the macOS menubar interface and follows a data/UI separation pattern.

### Data Layer (`src/data/`)
- **models.py** - Dataclasses for all domain objects (SessionInfo, CurrentSession, UsageLimits, AccountInfo, UsageSummary)
- **session_parser.py** - Parses Claude Code's JSONL session files from `~/.claude/projects/`. Handles the path encoding scheme where `/` becomes `-` and `/_` becomes `--`
- **account_parser.py** - Reads account info from `~/.claude.json`
- **usage_api.py** - Fetches usage limits from Anthropic API using OAuth token from macOS Keychain (`Claude Code-credentials`)

### UI Layer (`src/ui/`)
- **menu_builder.py** - Constructs the menubar menu structure from UsageSummary data
- **formatters.py** - Pure functions for display formatting (tokens, percentages, progress bars, relative times)

### Main App (`src/main.py`)
- **ClaudeUsageApp** - The rumps.App subclass that orchestrates data fetching and menu building on a 60-second refresh timer

## Key Implementation Details

- Session files are JSONL format; the parser handles very large files (>10MB) by sampling the beginning and estimating totals
- OAuth tokens are retrieved from macOS Keychain and cached for 30 seconds
- The menubar title shows 7-day utilization percentage or a warning icon if token expired
- Clicking a recent session opens Terminal and runs `claude --resume <session_id>`
