"""Fetch usage limits from Anthropic API."""

import json
import subprocess
import time
from datetime import datetime, timezone
from typing import Optional

import requests

from ..config import USAGE_API_URL, KEYCHAIN_SERVICE, API_CACHE_DURATION
from .models import UsageLimits


class UsageAPIClient:
    """Client for fetching usage limits from Anthropic API."""

    def __init__(self):
        self._cache: Optional[UsageLimits] = None
        self._cache_time: float = 0

    def _get_credentials(self) -> Optional[dict]:
        """Get full credentials from macOS Keychain."""
        try:
            result = subprocess.run(
                ["security", "find-generic-password", "-s", KEYCHAIN_SERVICE, "-w"],
                capture_output=True,
                text=True,
            )
            if result.returncode == 0:
                creds = json.loads(result.stdout.strip())
                return creds.get("claudeAiOauth", {})
        except (json.JSONDecodeError, subprocess.SubprocessError):
            pass
        return None

    def _is_token_expired(self, creds: dict) -> bool:
        """Check if the access token has expired."""
        expires_at = creds.get("expiresAt", 0)
        # Add 5 minute buffer
        return time.time() * 1000 > expires_at - 300000

    def get_oauth_token(self) -> Optional[str]:
        """Get OAuth token from macOS Keychain.

        Note: Token refresh is handled by Claude Code itself.
        If the token is expired, we return it anyway and let the
        API call fail gracefully.
        """
        creds = self._get_credentials()
        if not creds:
            return None
        return creds.get("accessToken")

    def is_token_expired(self) -> bool:
        """Check if the stored token appears to be expired."""
        creds = self._get_credentials()
        if not creds:
            return True
        return self._is_token_expired(creds)

    def fetch_usage(self, force_refresh: bool = False) -> Optional[UsageLimits]:
        """Fetch usage limits from API with caching."""
        # Check cache
        if not force_refresh and self._cache:
            if time.time() - self._cache_time < API_CACHE_DURATION:
                return self._cache

        token = self.get_oauth_token()
        if not token:
            return None

        try:
            response = requests.get(
                USAGE_API_URL,
                headers={
                    "Authorization": f"Bearer {token}",
                    "anthropic-beta": "oauth-2025-04-20",
                    "Accept": "application/json",
                },
                timeout=10,
            )

            if not response.ok:
                return self._cache  # Return cached data on error

            data = response.json()
            limits = self._parse_response(data)

            # Update cache
            self._cache = limits
            self._cache_time = time.time()

            return limits

        except (requests.RequestException, json.JSONDecodeError):
            return self._cache  # Return cached data on error

    def _parse_response(self, data: dict) -> UsageLimits:
        """Parse API response into UsageLimits."""
        five_hour = data.get("five_hour", {})
        seven_day = data.get("seven_day", {})
        opus = data.get("seven_day_opus", {})

        return UsageLimits(
            five_hour_utilization=five_hour.get("utilization", 0.0),
            five_hour_resets_at=self._parse_reset_time(five_hour.get("resets_at")),
            seven_day_utilization=seven_day.get("utilization", 0.0),
            seven_day_resets_at=self._parse_reset_time(seven_day.get("resets_at")),
            opus_utilization=opus.get("utilization", 0.0) if opus else 0.0,
            opus_resets_at=self._parse_reset_time(opus.get("resets_at") if opus else None),
        )

    def _parse_reset_time(self, ts_str: Optional[str]) -> Optional[datetime]:
        """Parse reset timestamp."""
        if not ts_str:
            return None
        try:
            ts_str = ts_str.replace("Z", "+00:00")
            return datetime.fromisoformat(ts_str)
        except ValueError:
            return None
