"""Parse stats-cache.json for usage statistics."""

import json
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any

from ..config import STATS_CACHE


class StatsParser:
    """Parse Claude Code stats cache."""

    def __init__(self, stats_path: Path = STATS_CACHE):
        self.stats_path = stats_path

    def load_stats(self) -> Dict[str, Any]:
        """Load and parse stats-cache.json."""
        if not self.stats_path.exists():
            return {}
        try:
            with open(self.stats_path) as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return {}

    def get_today_activity(self) -> Dict[str, int]:
        """Get today's activity stats."""
        stats = self.load_stats()
        today = datetime.now().strftime("%Y-%m-%d")

        for day in stats.get("dailyActivity", []):
            if day.get("date") == today:
                return {
                    "message_count": day.get("messageCount", 0),
                    "session_count": day.get("sessionCount", 0),
                    "tool_call_count": day.get("toolCallCount", 0),
                }

        return {"message_count": 0, "session_count": 0, "tool_call_count": 0}

    def get_today_tokens(self) -> Dict[str, int]:
        """Get today's token usage by model."""
        stats = self.load_stats()
        today = datetime.now().strftime("%Y-%m-%d")

        for day in stats.get("dailyModelTokens", []):
            if day.get("date") == today:
                return day.get("tokensByModel", {})

        return {}

    def get_weekly_tokens(self) -> Dict[str, int]:
        """Get last 7 days of token usage by model."""
        stats = self.load_stats()
        week_ago = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d")
        weekly_totals: Dict[str, int] = {}

        for day in stats.get("dailyModelTokens", []):
            if day.get("date", "") >= week_ago:
                for model, tokens in day.get("tokensByModel", {}).items():
                    weekly_totals[model] = weekly_totals.get(model, 0) + tokens

        return weekly_totals

    def get_total_stats(self) -> Dict[str, int]:
        """Get total stats across all time."""
        stats = self.load_stats()
        return {
            "total_sessions": stats.get("totalSessions", 0),
            "total_messages": stats.get("totalMessages", 0),
        }
