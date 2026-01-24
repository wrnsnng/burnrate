"""Configuration and paths for Claude Code Usage Tracker."""

from pathlib import Path

# Claude Code data paths
CLAUDE_DIR = Path.home() / ".claude"
CLAUDE_CONFIG = Path.home() / ".claude.json"
STATS_CACHE = CLAUDE_DIR / "stats-cache.json"
PROJECTS_DIR = CLAUDE_DIR / "projects"

# API configuration
USAGE_API_URL = "https://api.anthropic.com/api/oauth/usage"
KEYCHAIN_SERVICE = "Claude Code-credentials"

# App settings
REFRESH_INTERVAL = 60  # seconds
API_CACHE_DURATION = 30  # seconds
MAX_RECENT_SESSIONS = 8
