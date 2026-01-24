"""Data models for Claude Code Usage Tracker."""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, List


@dataclass
class SessionInfo:
    """Information about a Claude Code session."""
    session_id: str
    slug: str
    project_path: str
    encoded_project: str
    timestamp: datetime
    message_count: int
    total_tokens: int = 0
    summary: Optional[str] = None
    model: str = "unknown"


@dataclass
class CurrentSession:
    """Detailed information about the currently active session."""
    session_id: str
    slug: str
    project_path: str
    start_time: datetime
    input_tokens: int = 0
    output_tokens: int = 0
    cache_read_tokens: int = 0
    cache_creation_tokens: int = 0
    message_count: int = 0

    @property
    def total_tokens(self) -> int:
        """Calculate total tokens used in this session."""
        return self.input_tokens + self.output_tokens


@dataclass
class UsageLimits:
    """Usage limits from the Anthropic API."""
    five_hour_utilization: float = 0.0
    five_hour_resets_at: Optional[datetime] = None
    seven_day_utilization: float = 0.0
    seven_day_resets_at: Optional[datetime] = None
    opus_utilization: float = 0.0
    opus_resets_at: Optional[datetime] = None


@dataclass
class AccountInfo:
    """Account information from ~/.claude.json."""
    has_extra_usage_enabled: bool = False
    billing_type: str = "unknown"
    email: Optional[str] = None


@dataclass
class UsageSummary:
    """Complete usage summary for display in the menu."""
    current_session: Optional[CurrentSession] = None
    usage_limits: Optional[UsageLimits] = None
    account_info: Optional[AccountInfo] = None
    recent_sessions: List[SessionInfo] = field(default_factory=list)
    error_message: Optional[str] = None
