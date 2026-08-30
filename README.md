# claude-statusline

My Claude Code status line, versioned so every machine gets the same one.

```
~/workspace/claude-statusline | Opus | ⎇ main | (+3,-1) | +156 -23
[██████░░░░░░░░░░] 76k/200k (38%) | Block: 42m | Session: 23.5% | Weekly Sonnet: 12% | Weekly Opus: 41% | Weekly Reset: 3d
```

Line 1 is where you are. Line 2 is what you have left.

## Install

```bash
git clone <this-repo> ~/workspace/claude-statusline
cd ~/workspace/claude-statusline
./install.sh
```

Restart Claude Code. The repo can live anywhere; `install.sh` works out its own
location.

Re-run `install.sh` any time. It backs up anything it would overwrite and is
safe to run twice.

## What it does to your machine

| Path | What happens |
|---|---|
| `vendor/` | pinned ccstatusline install, gitignored |
| `~/.claude-statusline` | symlink to this repo |
| `~/.config/ccstatusline/settings.json` | symlink to `ccstatusline/settings.json` here |
| `~/.claude/settings.json` | only the `statusLine` block is rewritten |

Anything it replaces is copied to `<file>.bak-<timestamp>` first. To undo,
delete the two symlinks and restore the newest backup.

## Design notes

**Built on [ccstatusline](https://github.com/sirmalloc/ccstatusline), not a
hand-rolled script.** Weekly usage tracking, git caching, and flex layout are
already solved there. This repo is the config plus one widget ccstatusline
does not have.

**The version is pinned and vendored.** The common setup is
`npx -y ccstatusline@latest`, which re-resolves the npm registry on every
redraw. Measured on this machine:

| | per render |
|---|---|
| `npx -y ccstatusline@latest` | ~590 ms |
| vendored, pinned | ~220 ms |

The status line redraws after every assistant message, so that is ~370 ms back
each time. Bump `CCSTATUSLINE_VERSION` in `install.sh` to upgrade.

**`bin/code-velocity.sh` exists because ccstatusline has no widget for it.**
Claude Code reports `cost.total_lines_added` and `cost.total_lines_removed`;
nothing built in shows them. It is wired in as a `custom-command` widget and
prints nothing when no lines have changed, so it disappears instead of showing
`+0 -0`. No `jq` dependency.

## Editing the status line

Interactively:

```bash
node vendor/node_modules/ccstatusline/dist/ccstatusline.js
```

The TUI writes to `~/.config/ccstatusline/settings.json`, which is a symlink
into this repo, so your edits land here. Commit them.

By hand: edit `ccstatusline/settings.json`, then check the render:

```bash
node vendor/node_modules/ccstatusline/dist/ccstatusline.js < test/sample.json
```

`test/sample.json` is a realistic payload of what Claude Code pipes in. Widen
or narrow the result with `CCSTATUSLINE_WIDTH=80`.

Widgets worth knowing about that are not currently used: `cache-hit-rate`,
`output-speed`, `git-ahead-behind`, `git-pr`, `git-ci-status`,
`compaction-counter`, `thinking-effort`.

## Files

```
ccstatusline/settings.json   the status line itself
bin/code-velocity.sh         +added -removed widget
install.sh                   idempotent installer
test/sample.json             fixture for rendering offline
PLAN.org                     build log and decisions
```
