#!/bin/bash
# Installs runtime dependencies for the ppt-design-skill in .claude/skills.
set -euo pipefail

# Only run in Claude Code on the web (cloud) sessions.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

# Python library the skill builds decks with.
if ! python3 -c "import pptx_designer" >/dev/null 2>&1; then
  python3 -m pip install --quiet --upgrade pptx-designer
fi

# Poppler (pdftoppm) for the LibreOffice + Poppler PNG render fallback.
if ! command -v pdftoppm >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get install -y -qq poppler-utils >/dev/null 2>&1 \
    || { $SUDO apt-get update -qq >/dev/null 2>&1 && $SUDO apt-get install -y -qq poppler-utils >/dev/null; }
fi
