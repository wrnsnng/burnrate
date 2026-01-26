#!/usr/bin/env bash
#
# Burnrate Release Script
#
# Builds, signs, notarizes, and packages the macOS menubar app.
#
# Usage:
#   ./scripts/release.sh [version]
#
# Required environment variables (in .env.release):
#   APPLE_ID        - Your Apple ID email
#   APPLE_TEAM_ID   - Your Apple Developer Team ID
#
# Optional:
#   SIGNING_IDENTITY - Full signing identity (defaults to "Developer ID Application: ($APPLE_TEAM_ID)")
#   KEYCHAIN_PROFILE - Notarytool keychain profile name (defaults to "AC_PASSWORD")
#
# First-time setup for notarization:
#   xcrun notarytool store-credentials "AC_PASSWORD" \
#     --apple-id "your@email.com" \
#     --team-id "XXXXXXXXXX" \
#     --password "your-app-specific-password"
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Validate semver format
validate_version() {
  local version=$1
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?(-[a-zA-Z0-9]+)?$ ]]; then
    error "Invalid version format '$version'. Expected semver (e.g., 1.0.0, 2.1.0-beta)"
  fi
}

# Change to repo root
cd "$(dirname "$0")/.."
REPO_ROOT=$(pwd)

info "Burnrate Release Script"
info "Working directory: $REPO_ROOT"

# Load release environment variables
if [ -f "$REPO_ROOT/.env.release" ]; then
  info "Loading environment from .env.release"
  set -a
  source "$REPO_ROOT/.env.release"
  set +a
else
  warn ".env.release not found - notarization will be skipped"
fi

echo ""

# Get current version from Info.plist
CURRENT_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)

# Get version argument or prompt
VERSION_ARG=${1:-}

if [ -n "$VERSION_ARG" ]; then
  VERSION=$VERSION_ARG
  validate_version "$VERSION"
elif [ -t 0 ]; then
  info "Current version: $CURRENT_VERSION"
  read -rp "Enter new version (or press Enter to keep current): " VERSION_INPUT
  if [ -n "$VERSION_INPUT" ]; then
    VERSION=$VERSION_INPUT
    validate_version "$VERSION"
  else
    VERSION=$CURRENT_VERSION
  fi
else
  VERSION=$CURRENT_VERSION
fi

# Update version in Info.plist if changed
if [ "$VERSION" != "$CURRENT_VERSION" ]; then
  info "Bumping version to $VERSION..."
  /usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $VERSION" Resources/Info.plist
  /usr/libexec/PlistBuddy -c "Set CFBundleVersion $VERSION" Resources/Info.plist
  success "Version bumped to $VERSION"
else
  info "Using current version: $VERSION"
fi

echo ""
info "Building Burnrate v$VERSION..."
echo ""

# Build release binary
info "[1/6] Building release binary..."
swift build -c release
success "Build complete"

# Create app bundle
info "[2/6] Creating app bundle..."
APP_PATH="$REPO_ROOT/Burnrate.app"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

cp .build/release/Burnrate "$APP_PATH/Contents/MacOS/"
cp Resources/Info.plist "$APP_PATH/Contents/"

# Copy icon if exists
if [ -f "Resources/AppIcon.icns" ]; then
  cp Resources/AppIcon.icns "$APP_PATH/Contents/Resources/"
fi

success "App bundle created"

# Code signing
if [ -n "${APPLE_TEAM_ID:-}" ]; then
  # Use provided signing identity or construct from team ID
  SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application ($APPLE_TEAM_ID)}"

  info "[3/6] Signing app with hardened runtime..."
  info "Using identity: $SIGNING_IDENTITY"
  codesign --force --deep --options runtime --timestamp \
    --sign "$SIGNING_IDENTITY" \
    --entitlements "Resources/Burnrate.entitlements" \
    "$APP_PATH"

  # Verify signature
  codesign --verify --deep --strict "$APP_PATH"
  success "App signed and verified"
else
  warn "[3/6] Skipping code signing - APPLE_TEAM_ID not set"
fi

# Notarization using keychain profile (secure - no credentials in process list)
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-AC_PASSWORD}"

if [ -n "${APPLE_TEAM_ID:-}" ]; then
  # Check if keychain profile exists
  if xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" &>/dev/null; then
    info "[4/6] Creating ZIP for notarization..."
    ZIP_PATH="$REPO_ROOT/Burnrate-notarize.zip"
    rm -f "$ZIP_PATH"
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

    info "[5/6] Submitting for notarization (this may take a few minutes)..."
    xcrun notarytool submit "$ZIP_PATH" \
      --keychain-profile "$KEYCHAIN_PROFILE" \
      --wait

    # Clean up notarization zip
    rm -f "$ZIP_PATH"

    info "[6/6] Stapling notarization ticket..."
    xcrun stapler staple "$APP_PATH"
    success "App notarized and stapled"
  else
    warn "[4-6/6] Skipping notarization - keychain profile '$KEYCHAIN_PROFILE' not found"
    warn "Run this command to set up notarization credentials:"
    warn "  xcrun notarytool store-credentials \"$KEYCHAIN_PROFILE\" --apple-id \"your@email.com\" --team-id \"YOUR_TEAM_ID\" --password \"app-specific-password\""
  fi
else
  warn "[4-6/6] Skipping notarization - APPLE_TEAM_ID not set"
fi

# Create distributable ZIP
DIST_DIR="$REPO_ROOT/dist"
mkdir -p "$DIST_DIR"
DIST_ZIP="$DIST_DIR/Burnrate-$VERSION.zip"
rm -f "$DIST_ZIP"
ditto -c -k --keepParent "$APP_PATH" "$DIST_ZIP"
success "Created distributable: $DIST_ZIP"

# Create git tag if version was bumped
if [ "$VERSION" != "$CURRENT_VERSION" ]; then
  echo ""
  info "Creating git commit and tag..."

  git add Resources/Info.plist
  git commit -m "chore: release v$VERSION"
  git tag -a "v$VERSION" -m "Release v$VERSION"

  read -rp "Push to origin? [y/N] " PUSH_CONFIRM
  if [[ "$PUSH_CONFIRM" =~ ^[Yy]$ ]]; then
    git push && git push origin "v$VERSION"
    success "Git tag v$VERSION created and pushed"
  else
    info "Skipping push - run 'git push && git push origin v$VERSION' manually"
  fi
else
  info "Skipping git tag (no version bump)"
fi

# Upload to GitHub releases if gh is available
if command -v gh &> /dev/null && [ -f "$DIST_ZIP" ]; then
  echo ""
  read -rp "Create GitHub release? [y/N] " RELEASE_CONFIRM
  if [[ "$RELEASE_CONFIRM" =~ ^[Yy]$ ]]; then
    info "Creating GitHub release v$VERSION..."

    if ! gh release create "v$VERSION" \
      --title "Burnrate v$VERSION" \
      --notes "Release v$VERSION" \
      "$DIST_ZIP"; then
      info "Release may already exist, attempting to upload asset..."
      gh release upload "v$VERSION" "$DIST_ZIP" --clobber
    fi

    success "GitHub release v$VERSION uploaded"
  fi
fi

echo ""
success "Release v$VERSION complete!"
info "Distributable: $DIST_ZIP"
info "App bundle: $APP_PATH"
