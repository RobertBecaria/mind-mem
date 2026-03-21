#!/bin/bash
# Mind-Mem Hooks Installer
# Adds auto-recall and auto-capture hooks to Claude Code settings.json

SETTINGS_FILE="$HOME/.claude/settings.json"
HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Mind-Mem Hooks Installer"
echo "========================"
echo ""
echo "This will add the following hooks to Claude Code:"
echo "  1. SessionStart (startup/resume) → Auto-recall recent decisions"
echo "  2. SessionStart (compact)        → Auto-capture session signals"
echo ""

if [ ! -f "$SETTINGS_FILE" ]; then
  echo "Error: Claude Code settings.json not found at $SETTINGS_FILE"
  exit 1
fi

echo "Hooks directory: $HOOKS_DIR"
echo ""
echo "Add these hooks to your Claude Code settings.json under 'hooks':"
echo ""
cat <<HOOKJSON
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOOKS_DIR/session-start-recall.sh",
            "timeout": 5000
          }
        ]
      },
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOOKS_DIR/session-end-capture.sh",
            "timeout": 10000
          }
        ]
      }
    ]
  }
}
HOOKJSON

echo ""
echo "Or run this script with --auto to patch settings.json automatically."

if [ "$1" = "--auto" ]; then
  # Check if jq is available
  if ! command -v jq &>/dev/null; then
    echo "Error: jq is required for --auto. Install with: brew install jq"
    exit 1
  fi

  # Backup settings
  cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"
  echo "Backed up settings to $SETTINGS_FILE.bak"

  # Add hooks using jq
  jq --arg recall_cmd "bash $HOOKS_DIR/session-start-recall.sh" \
     --arg capture_cmd "bash $HOOKS_DIR/session-end-capture.sh" '
    .hooks.SessionStart = (
      (.hooks.SessionStart // []) +
      [
        {
          "matcher": "startup|resume",
          "hooks": [{"type": "command", "command": $recall_cmd, "timeout": 5000}]
        },
        {
          "matcher": "compact",
          "hooks": [{"type": "command", "command": $capture_cmd, "timeout": 10000}]
        }
      ]
    )
  ' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

  echo "Hooks installed successfully!"
  echo "Restart Claude Code to activate."
fi
