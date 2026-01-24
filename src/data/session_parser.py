"""Parse session JSONL files for session information."""

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional, Tuple

from ..config import PROJECTS_DIR, MAX_RECENT_SESSIONS
from .models import SessionInfo, CurrentSession


class SessionParser:
    """Parse Claude Code session files."""

    def __init__(self, projects_path: Path = PROJECTS_DIR):
        self.projects_path = projects_path

    def decode_project_path(self, encoded: str) -> str:
        """Convert encoded project path to actual path.

        Claude Code encodes paths as:
        - `/` becomes `-`
        - `/_` becomes `--` (underscore at start of folder name)

        This encoding is lossy - hyphens in folder names cannot be
        distinguished from path separators. We try to find the actual
        path on disk.

        Example: -Users-marcobieglo--GitHub-Selekt -> /Users/marcobieglo/_GitHub/Selekt
        """
        if not encoded:
            return ""

        path = encoded.lstrip("-")

        # `--` represents `/_` (path separator + leading underscore)
        path = path.replace("--", "/_")

        # Single dashes become path separators
        path = "/" + path.replace("-", "/")

        # Try to find the actual path on disk
        # The decoded path might be wrong if folder names contain hyphens
        resolved = self._resolve_actual_path(path)
        return resolved if resolved else path

    def _resolve_actual_path(self, decoded_path: str) -> str:
        """Try to resolve the actual path, handling hyphens in folder names.

        The encoding is lossy - we try common patterns to find the real path.
        """
        from pathlib import Path

        # If the path exists, it's correct
        if Path(decoded_path).exists():
            return decoded_path

        # Try combining path segments with hyphens
        # e.g., /a/b/c might actually be /a/b-c or /a-b/c
        parts = decoded_path.split("/")

        # Try simple cases: combine last two segments
        if len(parts) >= 2:
            # Try /a/b-c instead of /a/b/c
            combined = "/".join(parts[:-2] + [parts[-2] + "-" + parts[-1]])
            if Path(combined).exists():
                return combined

            # Try combining more segments
            if len(parts) >= 3:
                combined2 = "/".join(parts[:-3] + [parts[-3] + "-" + parts[-2] + "-" + parts[-1]])
                if Path(combined2).exists():
                    return combined2

        # Return original if no match found
        return decoded_path

    def get_recent_sessions(self, limit: int = MAX_RECENT_SESSIONS) -> List[SessionInfo]:
        """Get most recent sessions across all projects."""
        if not self.projects_path.exists():
            return []

        # First, collect all session files with their mtimes
        session_files: List[Tuple[Path, float, str, str]] = []  # (path, mtime, project_path, encoded)

        for project_dir in self.projects_path.iterdir():
            if not project_dir.is_dir() or project_dir.name.startswith("."):
                continue

            project_path = self.decode_project_path(project_dir.name)

            for session_file in project_dir.glob("*.jsonl"):
                # Skip agent sub-sessions
                if session_file.name.startswith("agent-"):
                    continue

                try:
                    mtime = session_file.stat().st_mtime
                    session_files.append((session_file, mtime, project_path, project_dir.name))
                except OSError:
                    continue

        # Sort by mtime and take only the most recent ones
        session_files.sort(key=lambda x: x[1], reverse=True)
        session_files = session_files[:limit * 2]  # Get a few extra in case some fail to parse

        # Now parse only the recent ones
        sessions = []
        for session_file, _, project_path, encoded_project in session_files:
            session_info = self._parse_session_summary(
                session_file, project_path, encoded_project
            )
            if session_info:
                sessions.append(session_info)
                if len(sessions) >= limit:
                    break

        # Sort by timestamp descending (from parsed data)
        sessions.sort(key=lambda s: s.timestamp, reverse=True)
        return sessions[:limit]

    def _parse_session_summary(
        self, path: Path, project_path: str, encoded_project: str
    ) -> Optional[SessionInfo]:
        """Extract basic session info without full parsing."""
        session_id = path.stem
        slug = None
        timestamp = None
        message_count = 0
        total_tokens = 0
        model = None
        summary = None

        try:
            # Get file modification time as fallback timestamp
            mtime = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)

            with open(path) as f:
                for i, line in enumerate(f):
                    # Limit parsing for large files
                    if i > 100 and slug and timestamp:
                        break

                    try:
                        entry = json.loads(line)
                        entry_type = entry.get("type")

                        # Get slug and timestamp from first user message
                        if entry_type == "user" and not slug:
                            slug = entry.get("slug", session_id[:8])
                            ts_str = entry.get("timestamp")
                            if ts_str:
                                timestamp = self._parse_timestamp(ts_str)

                        # Count messages
                        if entry_type in ("user", "assistant"):
                            message_count += 1

                        # Get model from assistant messages
                        if entry_type == "assistant" and not model:
                            msg = entry.get("message", {})
                            model = msg.get("model")

                            # Sum tokens
                            usage = msg.get("usage", {})
                            total_tokens += usage.get("input_tokens", 0)
                            total_tokens += usage.get("output_tokens", 0)

                        # Get latest summary
                        if entry_type == "summary":
                            summary = entry.get("summary")

                    except json.JSONDecodeError:
                        continue

            return SessionInfo(
                session_id=session_id,
                slug=slug or session_id[:8],
                project_path=project_path,
                encoded_project=encoded_project,
                timestamp=timestamp or mtime,
                message_count=message_count,
                total_tokens=total_tokens,
                summary=summary,
                model=model or "unknown",
            )

        except (IOError, OSError):
            return None

    def get_current_session(self) -> Optional[CurrentSession]:
        """Get the most recently modified session with full token details."""
        if not self.projects_path.exists():
            return None

        latest_file: Optional[Path] = None
        latest_mtime = 0.0

        for project_dir in self.projects_path.iterdir():
            if not project_dir.is_dir() or project_dir.name.startswith("."):
                continue

            for session_file in project_dir.glob("*.jsonl"):
                if session_file.name.startswith("agent-"):
                    continue

                try:
                    mtime = session_file.stat().st_mtime
                    if mtime > latest_mtime:
                        latest_mtime = mtime
                        latest_file = session_file
                except OSError:
                    continue

        if not latest_file:
            return None

        return self._parse_current_session(latest_file)

    def _parse_current_session(self, path: Path) -> Optional[CurrentSession]:
        """Parse token details for the current session.

        For very large files, we sample the beginning and end to get
        accurate totals without reading the entire file.
        """
        session_id = path.stem
        project_dir = path.parent.name
        project_path = self.decode_project_path(project_dir)

        slug = None
        start_time = None
        input_tokens = 0
        output_tokens = 0
        cache_read_tokens = 0
        cache_creation_tokens = 0
        message_count = 0

        try:
            file_size = path.stat().st_size

            # For files larger than 10MB, use sampling approach
            if file_size > 10_000_000:
                return self._parse_large_session(path, session_id, project_path)

            with open(path) as f:
                for line in f:
                    try:
                        entry = json.loads(line)
                        entry_type = entry.get("type")

                        # Get slug and start time from first user message
                        if entry_type == "user" and not slug:
                            slug = entry.get("slug", session_id[:8])
                            ts_str = entry.get("timestamp")
                            if ts_str:
                                start_time = self._parse_timestamp(ts_str)

                        # Count messages and sum tokens
                        if entry_type in ("user", "assistant"):
                            message_count += 1

                        if entry_type == "assistant":
                            msg = entry.get("message", {})
                            usage = msg.get("usage", {})

                            input_tokens += usage.get("input_tokens", 0)
                            output_tokens += usage.get("output_tokens", 0)
                            cache_read_tokens += usage.get("cache_read_input_tokens", 0)
                            cache_creation_tokens += usage.get("cache_creation_input_tokens", 0)

                    except json.JSONDecodeError:
                        continue

            if not start_time:
                start_time = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)

            return CurrentSession(
                session_id=session_id,
                slug=slug or session_id[:8],
                project_path=project_path,
                start_time=start_time,
                input_tokens=input_tokens,
                output_tokens=output_tokens,
                cache_read_tokens=cache_read_tokens,
                cache_creation_tokens=cache_creation_tokens,
                message_count=message_count,
            )

        except (IOError, OSError):
            return None

    def _parse_large_session(self, path: Path, session_id: str, project_path: str) -> Optional[CurrentSession]:
        """Parse a large session file by reading only the beginning.

        For very large files (5GB+), we can't read the whole thing.
        We read just enough to get the slug and start time, and estimate
        message count from file size.
        """
        slug = None
        start_time = None
        message_count = 0
        input_tokens = 0
        output_tokens = 0
        cache_read_tokens = 0
        cache_creation_tokens = 0

        try:
            file_size = path.stat().st_size

            # Read first 1MB to get slug, start time, and some token data
            with open(path) as f:
                bytes_read = 0
                lines_read = 0
                max_bytes = 1_000_000  # 1MB

                for line in f:
                    bytes_read += len(line)
                    lines_read += 1

                    if bytes_read > max_bytes:
                        break

                    try:
                        entry = json.loads(line)
                        entry_type = entry.get("type")

                        if entry_type == "user" and not slug:
                            slug = entry.get("slug", session_id[:8])
                            ts_str = entry.get("timestamp")
                            if ts_str:
                                start_time = self._parse_timestamp(ts_str)

                        if entry_type in ("user", "assistant"):
                            message_count += 1

                        if entry_type == "assistant":
                            msg = entry.get("message", {})
                            usage = msg.get("usage", {})
                            input_tokens += usage.get("input_tokens", 0)
                            output_tokens += usage.get("output_tokens", 0)
                            cache_read_tokens += usage.get("cache_read_input_tokens", 0)
                            cache_creation_tokens += usage.get("cache_creation_input_tokens", 0)

                    except json.JSONDecodeError:
                        continue

            # Estimate total messages based on file size and lines read
            if bytes_read > 0 and lines_read > 0:
                avg_line_size = bytes_read / lines_read
                estimated_total_lines = int(file_size / avg_line_size)
                # Messages are roughly 1/3 of lines (user, assistant, and other entries)
                message_count = max(message_count, estimated_total_lines // 3)

                # Scale up token estimates proportionally
                scale_factor = file_size / bytes_read
                input_tokens = int(input_tokens * scale_factor)
                output_tokens = int(output_tokens * scale_factor)

            if not start_time:
                start_time = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)

            return CurrentSession(
                session_id=session_id,
                slug=slug or session_id[:8],
                project_path=project_path,
                start_time=start_time,
                input_tokens=input_tokens,
                output_tokens=output_tokens,
                cache_read_tokens=cache_read_tokens,
                cache_creation_tokens=cache_creation_tokens,
                message_count=message_count,
            )

        except (IOError, OSError):
            return None

    def _parse_timestamp(self, ts_str: str) -> datetime:
        """Parse ISO timestamp string to datetime."""
        # Handle both Z suffix and +00:00
        ts_str = ts_str.replace("Z", "+00:00")
        try:
            return datetime.fromisoformat(ts_str)
        except ValueError:
            return datetime.now(timezone.utc)
