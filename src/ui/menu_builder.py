"""Build the menu structure for the menubar app."""

import subprocess
from pathlib import Path
from typing import Callable, List, Optional, Any

import rumps

from ..data.models import UsageSummary, SessionInfo, CurrentSession, UsageLimits, AccountInfo
from .formatters import (
    format_tokens,
    format_percentage,
    format_progress_bar,
    format_relative_time,
    format_time_remaining,
    truncate_string,
)


class MenuBuilder:
    """Build the menu structure from usage data."""

    def __init__(self, open_session_callback: Callable[[SessionInfo], None]):
        self.open_session_callback = open_session_callback

    def build_menu(self, summary: UsageSummary, token_expired: bool = False) -> List[Any]:
        """Build the complete menu structure."""
        menu_items: List[Any] = []

        # Error message if present
        if summary.error_message:
            menu_items.append(rumps.MenuItem(f"Error: {summary.error_message}"))
            menu_items.append(None)  # Separator

        # Current Session section
        menu_items.extend(self._build_current_session_section(summary.current_session))

        # Usage Limits section
        menu_items.extend(self._build_usage_limits_section(summary.usage_limits, token_expired))

        # Extra Usage section
        menu_items.extend(self._build_extra_usage_section(summary.account_info))

        # Recent Sessions section
        menu_items.extend(self._build_recent_sessions_section(summary.recent_sessions))

        # Actions
        menu_items.append(None)  # Separator
        menu_items.append(rumps.MenuItem("Open Claude Code", callback=self._open_claude))
        menu_items.append(rumps.MenuItem("Refresh", callback=None))  # Callback set by main app

        menu_items.append(None)  # Separator
        menu_items.append(rumps.MenuItem("Quit", callback=rumps.quit_application))

        return menu_items

    def _build_current_session_section(
        self, session: Optional[CurrentSession]
    ) -> List[Any]:
        """Build the Current Session menu section."""
        items: List[Any] = []

        header = rumps.MenuItem("═══ Current Session ═══")
        header.set_callback(None)
        items.append(header)

        if session:
            items.append(rumps.MenuItem(session.slug, callback=None))
            items.append(
                rumps.MenuItem(
                    f"{format_tokens(session.total_tokens)} tokens · {session.message_count} messages",
                    callback=None,
                )
            )
            items.append(
                rumps.MenuItem(
                    f"Started {format_relative_time(session.start_time)}", callback=None
                )
            )
        else:
            items.append(rumps.MenuItem("No active session", callback=None))

        items.append(None)  # Separator
        return items

    def _build_usage_limits_section(
        self, limits: Optional[UsageLimits], token_expired: bool = False
    ) -> List[Any]:
        """Build the Usage Limits menu section."""
        items: List[Any] = []

        header = rumps.MenuItem("═══ Usage Limits ═══")
        header.set_callback(None)
        items.append(header)

        if limits:
            # 5-Hour usage
            bar_5h = format_progress_bar(limits.five_hour_utilization)
            pct_5h = format_percentage(limits.five_hour_utilization)
            items.append(rumps.MenuItem(f"5-Hour   {bar_5h}  {pct_5h}", callback=None))
            if limits.five_hour_resets_at:
                items.append(
                    rumps.MenuItem(
                        f"         Resets in {format_time_remaining(limits.five_hour_resets_at)}",
                        callback=None,
                    )
                )

            # 7-Day usage
            bar_7d = format_progress_bar(limits.seven_day_utilization)
            pct_7d = format_percentage(limits.seven_day_utilization)
            items.append(rumps.MenuItem(f"7-Day    {bar_7d}  {pct_7d}", callback=None))
            if limits.seven_day_resets_at:
                items.append(
                    rumps.MenuItem(
                        f"         Resets in {format_time_remaining(limits.seven_day_resets_at)}",
                        callback=None,
                    )
                )

            # Opus usage (if available)
            if limits.opus_utilization > 0 or limits.opus_resets_at:
                bar_opus = format_progress_bar(limits.opus_utilization)
                pct_opus = format_percentage(limits.opus_utilization)
                items.append(rumps.MenuItem(f"Opus     {bar_opus}  {pct_opus}", callback=None))
        elif token_expired:
            items.append(rumps.MenuItem("Token expired", callback=None))
            items.append(rumps.MenuItem("Run 'claude' to refresh", callback=None))
        else:
            items.append(rumps.MenuItem("Unable to fetch limits", callback=None))

        items.append(None)  # Separator
        return items

    def _build_extra_usage_section(
        self, account: Optional[AccountInfo]
    ) -> List[Any]:
        """Build the Extra Usage menu section."""
        items: List[Any] = []

        header = rumps.MenuItem("═══ Extra Usage ═══")
        header.set_callback(None)
        items.append(header)

        if account:
            if account.has_extra_usage_enabled:
                items.append(rumps.MenuItem("✓ Enabled", callback=None))
            else:
                items.append(rumps.MenuItem("✗ Not enabled", callback=None))
        else:
            items.append(rumps.MenuItem("Unknown", callback=None))

        items.append(None)  # Separator
        return items

    def _build_recent_sessions_section(
        self, sessions: List[SessionInfo]
    ) -> List[Any]:
        """Build the Recent Sessions menu section."""
        items: List[Any] = []

        header = rumps.MenuItem("═══ Recent Sessions ═══")
        header.set_callback(None)
        items.append(header)

        if not sessions:
            items.append(rumps.MenuItem("No recent sessions", callback=None))
            return items

        for session in sessions:
            project_name = Path(session.project_path).name or "Unknown"
            time_ago = format_relative_time(session.timestamp)
            tokens = format_tokens(session.total_tokens) if session.total_tokens else "?"

            # Create main session menu item
            session_item = rumps.MenuItem(
                f"▶ {truncate_string(session.slug, 25)}",
                callback=lambda _, s=session: self.open_session_callback(s),
            )

            # Add details as subtitle
            detail = rumps.MenuItem(
                f"    {project_name} · {time_ago} · {tokens} tok",
                callback=lambda _, s=session: self.open_session_callback(s),
            )

            items.append(session_item)
            items.append(detail)

        return items

    def _open_claude(self, _: Any) -> None:
        """Open Claude Code in a new terminal."""
        subprocess.Popen(
            [
                "osascript",
                "-e",
                'tell application "Terminal" to do script "claude"',
            ]
        )


def open_session_in_terminal(session: SessionInfo) -> None:
    """Open a Claude Code session in Terminal."""
    cmd = f'cd "{session.project_path}" && claude --resume {session.session_id}'
    subprocess.Popen(
        [
            "osascript",
            "-e",
            f'tell application "Terminal" to do script "{cmd}"',
        ]
    )
