#!/usr/bin/env bash
# ccstatusline custom-command widget: session code velocity.
# Reads Claude Code's status line JSON on stdin, prints "Δadded/removed".
# Prints nothing when no lines changed yet, so the widget stays hidden.
#
# The delta prefix keeps it distinct from the git-changes widget next to it.
# git-changes counts the uncommitted working tree; this counts what Claude
# wrote during this session.
#
# ccstatusline has no built-in widget for cost.total_lines_added /
# cost.total_lines_removed, which is why this exists. No jq dependency:
# the input is machine-generated JSON with a stable shape.
set -u

json=$(cat)

field() {
    printf '%s' "$json" \
        | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*[0-9]+" \
        | grep -oE '[0-9]+$' \
        | head -1
}

added=$(field total_lines_added)
removed=$(field total_lines_removed)
added=${added:-0}
removed=${removed:-0}

if [ "$added" = 0 ] && [ "$removed" = 0 ]; then
    exit 0
fi

printf '\033[2mΔ\033[0m\033[32m%s\033[0m\033[2m/\033[0m\033[31m%s\033[0m' "$added" "$removed"
