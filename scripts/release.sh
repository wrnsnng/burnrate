#!/usr/bin/env bash
#
# Burnrate Release Script
#
# Builds, signs, notarizes, and packages the macOS menubar app.
# Also generates Sparkle appcast.xml for auto-updates.
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
info "[1/8] Building release binary..."
swift build -c release
success "Build complete"

# Create app bundle
info "[2/8] Creating app bundle..."
APP_PATH="$REPO_ROOT/Burnrate.app"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"
mkdir -p "$APP_PATH/Contents/Frameworks"

cp .build/release/Burnrate "$APP_PATH/Contents/MacOS/"
cp Resources/Info.plist "$APP_PATH/Contents/"

# Copy icon if exists
if [ -f "Resources/AppIcon.icns" ]; then
  cp Resources/AppIcon.icns "$APP_PATH/Contents/Resources/"
fi

# Copy Sparkle framework
SPARKLE_PATH=".build/artifacts/sparkle/Sparkle/Sparkle.framework"
if [ -d "$SPARKLE_PATH" ]; then
  cp -R "$SPARKLE_PATH" "$APP_PATH/Contents/Frameworks/"
fi

success "App bundle created"

# Code signing
if [ -n "${APPLE_TEAM_ID:-}" ]; then
  # Use provided signing identity or construct from team ID
  SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application ($APPLE_TEAM_ID)}"

  info "[3/8] Signing app with hardened runtime..."
  info "Using identity: $SIGNING_IDENTITY"

  # Sign Sparkle framework first if it exists
  if [ -d "$APP_PATH/Contents/Frameworks/Sparkle.framework" ]; then
    codesign --force --options runtime --timestamp \
      --sign "$SIGNING_IDENTITY" \
      "$APP_PATH/Contents/Frameworks/Sparkle.framework"
  fi

  # Sign the main app
  codesign --force --options runtime --timestamp \
    --sign "$SIGNING_IDENTITY" \
    --entitlements "Resources/Burnrate.entitlements" \
    "$APP_PATH"

  # Verify signature
  codesign --verify --strict "$APP_PATH"
  success "App signed and verified"
else
  warn "[3/8] Skipping code signing - APPLE_TEAM_ID not set"
fi

# Notarization using keychain profile (secure - no credentials in process list)
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-AC_PASSWORD}"

if [ -n "${APPLE_TEAM_ID:-}" ]; then
  # Check if keychain profile exists
  if xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" &>/dev/null; then
    info "[4/8] Creating ZIP for notarization..."
    ZIP_PATH="$REPO_ROOT/Burnrate-notarize.zip"
    rm -f "$ZIP_PATH"
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

    info "[5/8] Submitting for notarization (this may take a few minutes)..."
    xcrun notarytool submit "$ZIP_PATH" \
      --keychain-profile "$KEYCHAIN_PROFILE" \
      --wait

    # Clean up notarization zip
    rm -f "$ZIP_PATH"

    info "[6/8] Stapling notarization ticket..."
    xcrun stapler staple "$APP_PATH"
    success "App notarized and stapled"
  else
    warn "[4-6/8] Skipping notarization - keychain profile '$KEYCHAIN_PROFILE' not found"
    warn "Run this command to set up notarization credentials:"
    warn "  xcrun notarytool store-credentials \"$KEYCHAIN_PROFILE\" --apple-id \"your@email.com\" --team-id \"YOUR_TEAM_ID\" --password \"app-specific-password\""
  fi
else
  warn "[4-6/8] Skipping notarization - APPLE_TEAM_ID not set"
fi

# Create distributable ZIP
DIST_DIR="$REPO_ROOT/dist"
mkdir -p "$DIST_DIR"
DIST_ZIP="$DIST_DIR/Burnrate-$VERSION.zip"
rm -f "$DIST_ZIP"
ditto -c -k --keepParent "$APP_PATH" "$DIST_ZIP"
success "Created distributable: $DIST_ZIP"

# Sign the update for Sparkle
info "[7/8] Signing update for Sparkle..."
SPARKLE_SIGN_TOOL=".build/artifacts/sparkle/Sparkle/bin/sign_update"
if [ ! -x "$SPARKLE_SIGN_TOOL" ]; then
  error "Sparkle sign_update tool not found at $SPARKLE_SIGN_TOOL"
fi

SPARKLE_SIGNATURE=$("$SPARKLE_SIGN_TOOL" "$DIST_ZIP" 2>&1 | grep "sparkle:edSignature=" | cut -d'"' -f2)
if [ -z "$SPARKLE_SIGNATURE" ]; then
  error "Failed to generate Sparkle signature - ensure EdDSA key is configured"
fi
success "Sparkle signature generated"

# Generate appcast.xml (committed to repo root for raw.githubusercontent.com access)
info "[8/8] Generating appcast.xml..."
APPCAST_PATH="$REPO_ROOT/appcast.xml"
FILE_SIZE=$(stat -f%z "$DIST_ZIP")
PUB_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S GMT")
DOWNLOAD_URL="https://github.com/wrnsnng/burnrate/releases/download/v$VERSION/Burnrate-$VERSION.zip"

cat > "$APPCAST_PATH" << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Burnrate Updates</title>
    <link>https://github.com/wrnsnng/burnrate/releases</link>
    <description>Most recent updates to Burnrate</description>
    <language>en</language>
    <item>
      <title>Version $VERSION</title>
      <pubDate>$PUB_DATE</pubDate>
      <sparkle:version>$VERSION</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure
        url="$DOWNLOAD_URL"
        length="$FILE_SIZE"
        type="application/octet-stream"
        sparkle:edSignature="$SPARKLE_SIGNATURE"
      />
    </item>
  </channel>
</rss>
EOF
success "Generated appcast.xml"

# Commit appcast.xml and create git tag
echo ""
info "Committing appcast.xml and creating release..."

git add appcast.xml
if [ "$VERSION" != "$CURRENT_VERSION" ]; then
  git add Resources/Info.plist
fi
git commit -m "chore: release v$VERSION"
git tag -a "v$VERSION" -m "Release v$VERSION"

read -rp "Push to origin? [y/N] " PUSH_CONFIRM
if [[ "$PUSH_CONFIRM" =~ ^[Yy]$ ]]; then
  git push && git push origin "v$VERSION"
  success "Git tag v$VERSION created and pushed"
else
  info "Skipping push - run 'git push && git push origin v$VERSION' manually"
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
      info "Release may already exist, attempting to upload assets..."
      gh release upload "v$VERSION" "$DIST_ZIP" --clobber
    fi

    success "GitHub release v$VERSION uploaded"
    info "Note: appcast.xml is committed to repo root and served via raw.githubusercontent.com"
  fi
fi

echo ""
success "Release v$VERSION complete!"
info "Distributable: $DIST_ZIP"
info "Appcast: $APPCAST_PATH (committed to repo root)"
info "App bundle: $APP_PATH"
