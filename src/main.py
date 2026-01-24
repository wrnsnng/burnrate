#!/usr/bin/env python3
"""Claude Code Usage Tracker - macOS Menubar App."""

import sys
import rumps
from PyObjCTools import AppHelper

from .config import REFRESH_INTERVAL
from .data.models import UsageSummary
from .data.session_parser import SessionParser
from .data.account_parser import AccountParser
from .data.usage_api import UsageAPIClient
from .ui.menu_builder import MenuBuilder, open_session_in_terminal
from .ui.formatters import format_percentage


def log(msg):
    """Log to stderr for debugging."""
    print(msg, file=sys.stderr, flush=True)


class ClaudeUsageApp(rumps.App):
    """Main menubar application."""

    def __init__(self):
        log("Initializing ClaudeUsageApp...")
        super().__init__(
            name="Claude Usage",
            title="⚡ --",
            quit_button=None,  # We add our own
        )
        log("rumps.App initialized")

        # Initialize data sources
        log("Creating SessionParser...")
        self.session_parser = SessionParser()
        log("Creating AccountParser...")
        self.account_parser = AccountParser()
        log("Creating UsageAPIClient...")
        self.usage_api = UsageAPIClient()

        # Initialize menu builder
        log("Creating MenuBuilder...")
        self.menu_builder = MenuBuilder(open_session_callback=open_session_in_terminal)

        # Initial data load
        log("Running initial refresh_data...")
        self.refresh_data(None)
        log("Initialization complete!")

    @rumps.timer(REFRESH_INTERVAL)
    def auto_refresh(self, _):
        """Periodically refresh data."""
        self.refresh_data(None)

    def refresh_data(self, _):
        """Refresh all data and rebuild menu."""
        try:
            # Fetch all data (thread-safe)
            current_session = self.session_parser.get_current_session()
            recent_sessions = self.session_parser.get_recent_sessions()
            account_info = self.account_parser.get_account_info()
            usage_limits = self.usage_api.fetch_usage()
            token_expired = self.usage_api.is_token_expired()

            # Build summary
            summary = UsageSummary(
                current_session=current_session,
                usage_limits=usage_limits,
                account_info=account_info,
                recent_sessions=recent_sessions,
            )

            # Determine new title
            if usage_limits:
                pct = format_percentage(usage_limits.seven_day_utilization)
                new_title = f"⚡ {pct}"
            elif token_expired:
                new_title = "⚡ ⚠️"
            else:
                new_title = "⚡ --"

            # Schedule UI updates on main thread
            AppHelper.callAfter(self._update_ui, new_title, summary, token_expired)

        except Exception as e:
            # Show error in menu
            summary = UsageSummary(error_message=str(e))
            AppHelper.callAfter(self._update_ui, "⚠️ Error", summary, False)

    def _update_ui(self, new_title: str, summary: UsageSummary, token_expired: bool):
        """Update UI elements (must be called on main thread)."""
        self.title = new_title
        self._rebuild_menu(summary, token_expired)

    def _rebuild_menu(self, summary: UsageSummary, token_expired: bool = False):
        """Rebuild the entire menu."""
        self.menu.clear()

        for item in self.menu_builder.build_menu(summary, token_expired):
            if item is None:
                self.menu.add(rumps.separator)
            elif isinstance(item, rumps.MenuItem):
                # Set refresh callback for the Refresh item
                if item.title == "Refresh":
                    item.set_callback(self.refresh_data)
                self.menu.add(item)


def main():
    """Entry point."""
    log("Starting main()...")
    app = ClaudeUsageApp()
    log(f"App created, title: {app.title}")
    log("Calling app.run() - menubar icon should appear now")
    app.run()
    log("app.run() returned (this shouldn't happen normally)")


if __name__ == "__main__":
    main()
