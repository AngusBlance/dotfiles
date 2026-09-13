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
- **Symlinked:** `claude/skills/` → `~/.claude/skills` and `claude/CLAUDE.md` → `~/.claude/CLAUDE.md`. They are the same files, so skills Claude creates and user-memory edits (`/memory`) land in this repo: review them before committing.
- **Merged into `~/.claude/settings.json`:** `claude/hooks.json` and `claude/settings.shared.json`. Every other setting stays local.
- **Copied:** `claude/scripts/` and `claude/sounds/`, which the hooks use.

Everything else stays on each machine: credentials, conversation history and project memory (`projects/`), caches, logs and `settings.local.json`.

Things to know:
- **Re-running `install.sh` re-applies shared settings**, so a local change to a shared key (e.g. `/model`) is reverted. If a value should differ per machine, remove it from `settings.shared.json`.
- **Permission lists are only ever added to.** Removing a rule from `settings.shared.json` doesn't remove it from machines that already have it.
- **Never put `hooks` in `settings.shared.json`.** Apart from the combined `permissions` lists, lists in it replace local ones, which would wipe the managed hooks; hooks belong in `hooks.json`.
- **Install from your main clone.** The symlinks point at whichever checkout ran `install.sh`, so moving or deleting it breaks them until you re-run it.