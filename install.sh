#!/usr/bin/env bash
# Install this status line for Claude Code on the current machine.
# Safe to re-run. Existing files are backed up, never overwritten in place.
set -euo pipefail

# Pinned so every machine renders the same status line. Bump deliberately.
CCSTATUSLINE_VERSION="2.2.27"

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STABLE_LINK="$HOME/.claude-statusline"
CC_CONFIG="$HOME/.config/ccstatusline/settings.json"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
ENTRY="$REPO/vendor/node_modules/ccstatusline/dist/ccstatusline.js"
STAMP="$(date +%Y%m%d-%H%M%S)"

say() { printf '  %s\n' "$*"; }
step() { printf '\n==> %s\n' "$*"; }

# Back up a path only if it is a real file, not one of our symlinks.
backup() {
    if [ -e "$1" ] && [ ! -L "$1" ]; then
        cp "$1" "$1.bak-$STAMP"
        say "backed up $1 -> $(basename "$1").bak-$STAMP"
    fi
}

step "Checking prerequisites"
for cmd in node npm git; do
    command -v "$cmd" >/dev/null || { echo "error: $cmd is required but not installed" >&2; exit 1; }
    say "$cmd $($cmd --version 2>/dev/null | head -1)"
done

step "Installing ccstatusline $CCSTATUSLINE_VERSION into vendor/"
# A pinned local copy instead of "npx ccstatusline@latest": npx re-resolves the
# registry on every render, which measured ~390 ms slower per status line draw.
if [ -f "$ENTRY" ] \
    && node -e "process.exit(require('$REPO/vendor/node_modules/ccstatusline/package.json').version==='$CCSTATUSLINE_VERSION'?0:1)" 2>/dev/null; then
    say "already at $CCSTATUSLINE_VERSION, skipping"
else
    npm install --silent --prefix "$REPO/vendor" "ccstatusline@$CCSTATUSLINE_VERSION"
    say "installed"
fi
[ -f "$ENTRY" ] || { echo "error: $ENTRY missing after install" >&2; exit 1; }

step "Linking $STABLE_LINK -> $REPO"
# The config refers to bin/ through this fixed path, so the committed
# settings.json stays machine-independent no matter where the repo is cloned.
ln -sfn "$REPO" "$STABLE_LINK"
say "$(readlink "$STABLE_LINK")"

step "Linking ccstatusline config"
mkdir -p "$(dirname "$CC_CONFIG")"
backup "$CC_CONFIG"
ln -sfn "$REPO/ccstatusline/settings.json" "$CC_CONFIG"
say "$CC_CONFIG -> $(readlink "$CC_CONFIG")"

step "Wiring statusLine into $CLAUDE_SETTINGS"
mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
PATCHED="$(mktemp)"
trap 'rm -f "$PATCHED"' EXIT
node -e '
const fs = require("fs");
const [file, entry, out] = process.argv.slice(1);
let settings = {};
if (fs.existsSync(file)) settings = JSON.parse(fs.readFileSync(file, "utf8"));
settings.statusLine = Object.assign(
    { padding: 0 },
    settings.statusLine,
    { type: "command", command: `node ${JSON.stringify(entry)}` }
);
fs.writeFileSync(out, JSON.stringify(settings, null, 2) + "\n");
' "$CLAUDE_SETTINGS" "$ENTRY" "$PATCHED"
# Only touch the file when the result differs, so reruns leave no backup trail.
if cmp -s "$PATCHED" "$CLAUDE_SETTINGS"; then
    say "already wired, unchanged"
else
    backup "$CLAUDE_SETTINGS"
    cp "$PATCHED" "$CLAUDE_SETTINGS"
    say "command: node $ENTRY"
fi

step "Verifying"
chmod +x "$REPO"/bin/*.sh
OUT="$(node "$ENTRY" < "$REPO/test/sample.json")"
[ -n "$OUT" ] || { echo "error: status line rendered empty" >&2; exit 1; }
printf '%s\n' "$OUT"

printf '\nDone. Restart Claude Code, or run /statusline to see it.\n'
