#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

REPO="0xSiddhant/xcodeproj_audit"
BINARY_NAME="xcodeproj_audit"
INSTALL_DIR="/usr/local/bin"
USE_SUDO=true

for arg in "$@"; do
  case "$arg" in
    --user)
      INSTALL_DIR="$HOME/.local/bin"
      USE_SUDO=false
      ;;
  esac
done

echo -e "${YELLOW}Fetching latest release...${RESET}"
VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep '"tag_name"' \
  | sed 's/.*"tag_name": *"\(.*\)".*/\1/')

if [ -z "$VERSION" ]; then
  echo -e "${RED}error: could not determine latest version${RESET}" >&2
  exit 1
fi

# Check if already installed and compare versions
CURRENT_VERSION=""
if command -v "$BINARY_NAME" &>/dev/null; then
  CURRENT_VERSION=$("$BINARY_NAME" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true)
fi

if [ -n "$CURRENT_VERSION" ] && [ "$CURRENT_VERSION" = "$VERSION" ]; then
  echo -e "${GREEN}$BINARY_NAME is already up to date (${VERSION})${RESET}"
  exit 0
fi

if [ -n "$CURRENT_VERSION" ]; then
  echo -e "${YELLOW}Updating $BINARY_NAME $CURRENT_VERSION → $VERSION...${RESET}"
else
  echo -e "${YELLOW}Installing $BINARY_NAME $VERSION...${RESET}"
fi

ARCHIVE="${BINARY_NAME}-${VERSION}-macos.zip"
URL="https://github.com/$REPO/releases/download/$VERSION/$ARCHIVE"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL "$URL" -o "$TMP_DIR/$ARCHIVE"
unzip -q "$TMP_DIR/$ARCHIVE" -d "$TMP_DIR"

if [ "$USE_SUDO" = true ]; then
  sudo mkdir -p "$INSTALL_DIR"
  sudo install -m 755 "$TMP_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
else
  mkdir -p "$INSTALL_DIR"
  install -m 755 "$TMP_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
fi

if [ -n "$CURRENT_VERSION" ]; then
  echo -e "${GREEN}$BINARY_NAME updated $CURRENT_VERSION → $VERSION${RESET}"
else
  echo -e "${GREEN}$BINARY_NAME $VERSION installed → $INSTALL_DIR/$BINARY_NAME${RESET}"
fi

if [ "$USE_SUDO" = false ] && [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo ""
  echo -e "${YELLOW}Add $INSTALL_DIR to your PATH:${RESET}"
  echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
fi
