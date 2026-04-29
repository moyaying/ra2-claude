#!/usr/bin/env bash
# Installer for the improved RA2-Claude sound system.
# - Copies sounds + ra2 CLI into ~/.claude/ra2/
# - Merges hooks into ~/.claude/settings.json (requires jq)
#
# Re-run is safe: idempotent, never overwrites existing user hooks; merges by
# appending entries that aren't already present.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$HOME/.claude/ra2"
SETTINGS="$HOME/.claude/settings.json"
HOOKS_SNIPPET="$SRC_DIR/hooks.json"

green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }
red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }

# 1) Copy sounds + script
mkdir -p "$DEST_DIR/sounds"/{start,prompt,done,compact,approval}
cp "$SRC_DIR/sounds/session-start.wav"    "$DEST_DIR/sounds/start/"
cp "$SRC_DIR/sounds/vpriata.wav"          "$DEST_DIR/sounds/prompt/"
cp "$SRC_DIR/sounds/task-complete.wav"    "$DEST_DIR/sounds/done/"
cp "$SRC_DIR/sounds/context-compact.wav"  "$DEST_DIR/sounds/compact/"
cp "$SRC_DIR/sounds/approval-needed.wav"  "$DEST_DIR/sounds/approval/"
cp "$SRC_DIR/ra2" "$DEST_DIR/ra2"
chmod +x "$DEST_DIR/ra2"
green "✓ files installed to $DEST_DIR"

# 2) Merge hooks into settings.json
if ! command -v jq >/dev/null 2>&1; then
  yellow "⚠ jq not found — skipping settings.json merge."
  yellow "  Install jq (brew install jq) and re-run, OR merge $HOOKS_SNIPPET manually into $SETTINGS"
  exit 0
fi

mkdir -p "$(dirname "$SETTINGS")"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

# Backup
cp "$SETTINGS" "$SETTINGS.bak.$(date +%s)"

tmp=$(mktemp)
# For each event in hooks.json, append our entry to the matching event array iff
# no existing entry uses our `ra2 play <event>` command (idempotent).
jq --slurpfile new "$HOOKS_SNIPPET" '
  . as $orig
  | .hooks = (
      ($orig.hooks // {}) as $cur
      | ($new[0].hooks) as $add
      | reduce ($add | keys[]) as $event ($cur;
          .[$event] = (
            (.[$event] // []) as $existing
            | ($add[$event][0]) as $new_entry
            | ($new_entry.hooks[0].command) as $cmd
            | if any($existing[]; (.hooks // [])[]?.command == $cmd)
                then $existing
                else $existing + [$new_entry]
              end
          )
        )
    )
' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"

green "✓ hooks merged into $SETTINGS (backup saved as $SETTINGS.bak.*)"

# 3) Friendly hint
echo
green "Done. Try:"
echo "  $DEST_DIR/ra2 status"
echo "  $DEST_DIR/ra2 test done"
echo "  $DEST_DIR/ra2 disable     # silence without removing"
echo
echo "Optional: add to PATH for shorter access:"
echo "  ln -sf $DEST_DIR/ra2 /usr/local/bin/ra2"
