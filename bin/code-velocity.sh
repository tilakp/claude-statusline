#!/usr/bin/env bash
# ccstatusline custom-command widget: session code velocity.
# Reads Claude Code's status line JSON on stdin, prints "+added -removed".
# Prints nothing when no lines changed yet, so the widget stays hidden.
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

printf '\033[32m+%s\033[0m \033[31m-%s\033[0m' "$added" "$removed"
