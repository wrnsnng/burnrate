"""Parse ~/.claude.json for account information."""

import json
from pathlib import Path
from typing import Optional

from ..config import CLAUDE_CONFIG
from .models import AccountInfo


class AccountParser:
    """Parse Claude Code configuration for account info."""

    def __init__(self, config_path: Path = CLAUDE_CONFIG):
        self.config_path = config_path

    def get_account_info(self) -> AccountInfo:
        """Extract account information from config."""
        if not self.config_path.exists():
            return AccountInfo()

        try:
            with open(self.config_path) as f:
                config = json.load(f)
        except (json.JSONDecodeError, IOError):
            return AccountInfo()

        # Get OAuth account info
        oauth_account = config.get("oauthAccount", {})

        return AccountInfo(
            has_extra_usage_enabled=oauth_account.get("hasExtraUsageEnabled", False),
            billing_type=oauth_account.get("billingType", "unknown"),
            email=oauth_account.get("emailAddress"),
        )
