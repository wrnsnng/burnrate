"""Formatting utilities for display."""

from datetime import datetime, timezone


def format_tokens(tokens: int) -> str:
    """Format token count with K/M suffix.

    Examples:
        1234 -> "1.2K"
        1234567 -> "1.2M"
    """
    if tokens >= 1_000_000:
        return f"{tokens / 1_000_000:.1f}M"
    elif tokens >= 1_000:
        return f"{tokens / 1_000:.1f}K"
    return str(tokens)


def format_percentage(value: float) -> str:
    """Format percentage value.

    Examples:
        35.5 -> "36%"
        0.0 -> "0%"
    """
    return f"{int(round(value))}%"


def format_progress_bar(percentage: float, width: int = 10) -> str:
    """Create a text-based progress bar.

    Examples:
        35.0, 10 -> "████░░░░░░"
        100.0, 10 -> "██████████"
    """
    filled = int(round(percentage / 100 * width))
    filled = max(0, min(width, filled))  # Clamp to valid range
    empty = width - filled

    return "█" * filled + "░" * empty


def format_relative_time(dt: datetime) -> str:
    """Format datetime as relative time.

    Examples:
        5 minutes ago -> "5m ago"
        2 hours ago -> "2h ago"
        3 days ago -> "3d ago"
    """
    now = datetime.now(timezone.utc)

    # Ensure dt has timezone info
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)

    delta = now - dt
    total_seconds = int(delta.total_seconds())

    if total_seconds < 0:
        return "just now"

    if total_seconds < 60:
        return "just now"
    elif total_seconds < 3600:
        minutes = total_seconds // 60
        return f"{minutes}m ago"
    elif total_seconds < 86400:
        hours = total_seconds // 3600
        return f"{hours}h ago"
    elif total_seconds < 604800:  # 7 days
        days = total_seconds // 86400
        return f"{days}d ago"
    else:
        return dt.strftime("%b %d")


def format_time_remaining(dt: datetime) -> str:
    """Format time remaining until a future datetime.

    Examples:
        4 hours from now -> "4h 23m"
        3 days from now -> "3d 14h"
    """
    now = datetime.now(timezone.utc)

    # Ensure dt has timezone info
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)

    delta = dt - now
    total_seconds = int(delta.total_seconds())

    if total_seconds <= 0:
        return "now"

    days = total_seconds // 86400
    hours = (total_seconds % 86400) // 3600
    minutes = (total_seconds % 3600) // 60

    if days > 0:
        return f"{days}d {hours}h"
    elif hours > 0:
        return f"{hours}h {minutes}m"
    else:
        return f"{minutes}m"


def truncate_string(s: str, max_length: int = 30) -> str:
    """Truncate string with ellipsis if too long."""
    if len(s) <= max_length:
        return s
    return s[: max_length - 3] + "..."
