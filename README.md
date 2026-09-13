# nvim

## Setup

On a fresh machine, the whole setup is:
```
git clone git@github.com:AngusBlance/dotfiles.git
./dotfiles/install.sh
```
The hook itself tries `afplay` → `paplay` → `aplay` → terminal bell, so it degrades gracefully on macOS, other Linux audio stacks, or a bare server with no player at all.

## Claude Code

`install.sh` sets up `~/.claude` from `claude/`:
- `skills/` and `CLAUDE.md` are symlinked, so new skills and `/memory` edits land in this repo.
- `hooks.json` and `settings.shared.json` are merged into `settings.json`; other settings stay local.
- `scripts/` and `sounds/` are copied for the hooks.

Credentials, history, `projects/` and caches are never synced. Re-running `install.sh` re-applies shared settings, and permission lists only grow. Keep hooks out of `settings.shared.json`.