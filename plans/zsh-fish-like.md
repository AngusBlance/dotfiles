# Plan: a fish-like zsh, without a framework

Status: **approved-pending — all decisions resolved, nothing implemented.** Awaiting your go-ahead.
Revision 3 — final. Stability-first, tmux-first, startup time explicitly not a goal.

## Rules this plan follows

1. **Stability beats fish-parity.** Anything jank is dropped, not worked around.
2. **tmux wins every conflict.** Everything you do lives in tmux; nothing here may risk it.
3. **Startup time is not a priority.** No caching, no lazy-loading, no micro-optimisation.
4. Third-party deps are installed by a script inside `zsh/`.
5. Starship and `tmux/` are not touched.

**Rule 3 is load-bearing and worth stating plainly:** every performance optimisation from the
earlier revisions is now dropped, and *each one removed was also a risk*. Stability-first and
speed-indifferent point the same way here. Specifically:

| Earlier proposal | Now | Risk this removes |
|---|---|---|
| `compinit -C` + daily rebuild | **Keep full `compinit`** | No stale-completions window after installing a tool |
| Static brew exports | **Keep `eval "$(brew shellenv)"`** | No hard-coded `/opt/homebrew`; portable to Intel/Linuxbrew unchanged |
| Cache `starship init` | **Keep plain `eval`** | No silently-stale prompt after `brew upgrade starship` |
| `zcompile` rc files | **Skip** | No build artefacts to go out of sync |

Expected startup stays around today's ~113 ms. That is fine.

---

## 1. What exists today

### Install conventions

| Thing | Where |
|---|---|
| Entry point | `install.sh` — sources every `scripts/install_*.sh`, calls `install_<tool>` |
| Helper | `scripts/lib.sh` → `link_config <src> <target>`; backs up to `*.pre-dotfiles.bak`, then symlinks |
| zsh installer | `scripts/install_zsh.sh` |
| Tests | `tests/test-*.sh`, plain bash |

Two symlink strategies coexist deliberately: **tmux** symlinks the whole directory; **zsh** links
file-by-file, because zsh writes `.zsh_history` and `.zcompdump` into `ZDOTDIR`, which must not be
tracked. `ZDOTDIR=~/.config/zsh`. Both verified live.

### Pre-existing problems found

1. **`LS_COLORS` is empty**, so `zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"` does
   nothing today — completion menus are uncoloured. Fixed by setting `LS_COLORS`.
2. **`setopt CORRECT`** — "did you mean…?" prompts. Not fish-like, and an ongoing irritant.
   **Dropping** (agreed).
3. **`_approximate` / `_correct` completers** — add Tab latency and guess at your intent.
   **Dropping** (agreed) — this is a stability improvement, not a regression.
4. **Redundant `~/.config/zsh/.zprofile`** — contains only `eval "$(brew shellenv)"`, which the
   `.zshrc` brew block now supersedes for both login and non-login shells. Untracked, from June.
   **Recommend deleting; not touched without your word.**
5. **Three stale `.zcompdump*` files** in `~/.config/zsh` (two host-suffixed, from July). Cruft.
6. `alias ls='ls --color=auto'` is **fine** — macOS 26's BSD `ls` accepts `--color`. I expected
   this to be broken, checked, and it isn't.

### Reference timings (informational only, given rule 3)

Measured on this machine, zsh 5.9, medians of 12–15 runs: total `zsh -i -c exit` **112.6 ms**;
`zsh -f` floor 9.3 ms; `compinit` 38.8 ms; `eval "$(brew shellenv)"` 23.2 ms;
`eval "$(starship init zsh)"` 20.7 ms; fzf sourcing ~2.7 ms; z-sy-h highlighter load 4.7 ms.

Recorded so that if startup ever *does* start bothering you, the levers are already costed:
brew→static saves ~23 ms, `compinit -C` saves ~20 ms, starship cache saves ~7 ms. Under 50 ms is
not reachable while keeping both Starship and tab completion — the floor is ~42 ms before any
feature or plugin.

---

## 2. Features

### Included — built-in zsh, the two plugins, and fzf

**Phase 1 contains no custom widgets and no custom functions beyond a one-line `cdh`.** It is
options, zstyles, keybindings and three well-known third-party sources. That is the whole reason
it should be stable.

| # | Feature | Approach | Notes |
|---|---|---|---|
| 1 | Autosuggestions; Right/Ctrl-F accept; Alt-Right by word | `zsh-autosuggestions` | Right and Ctrl-F are both `forward-char`, already in the plugin's default accept-widgets — no binding needed. Bind Alt-Right (`^[[1;3C` **and** `^[^[[C`) to `forward-word`. Set `ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20` to avoid suggestions on very long lines. |
| 2 | Syntax highlighting | `zsh-syntax-highlighting`, **loaded last** | `main` + `brackets` highlighters. Covers valid/invalid commands, existing paths, quotes, unclosed strings. |
| 3 | Completion menu, arrow-navigable, with descriptions | built-in | `zmodload zsh/complist`; `menu select`, `group-name ''`, `verbose yes`, `descriptions` format; Shift-Tab → `reverse-menu-complete`. |
| 4 | Case-insensitive + partial-word matching | built-in | `matcher-list`: case-fold, then `r:\|[._-]=* r:\|=*`, then substring. |
| 5 | Up/Down filtered by typed prefix | built-in | `up-line-or-beginning-search` / `down-line-or-beginning-search`, bound to arrows and the `terminfo` keys. Exact fish behaviour, no plugin. |
| 6 | Ctrl-R interactive history | fzf (kept) | Also gives Ctrl-T and Alt-C. |
| 7 | Deduplicated history, shared file | built-in | `HIST_IGNORE_ALL_DUPS`, `HIST_SAVE_NO_DUPS`, `HIST_FIND_NO_DUPS`, `HIST_REDUCE_BLANKS`, `EXTENDED_HISTORY`, plus **`INC_APPEND_HISTORY_TIME` in place of `SHARE_HISTORY`** — see below. |
| 9 | Auto-cd | built-in | `AUTO_CD`, already on. Nothing to do. |
| 10 | Directory stack (partial) | built-in | `AUTO_PUSHD`, `PUSHD_IGNORE_DUPS`, `PUSHD_SILENT` give `cd -<n>` and `dirs -v` free; one-line `cdh` pipes `dirs -v` to fzf. |
| 11 | Alt-E / Ctrl-X Ctrl-E → `$EDITOR` | built-in | `edit-command-line`. Exact match. |
| 12 | Alt-H / F1 → man page | built-in | `run-help` is already `ESC-h`; needs `unalias run-help` plus autoloading `run-help-git`/`-ssh`/`-sudo`. Arguably better than fish's — `run-help-git` understands subcommands. |
| 13 | Alt-. → last argument | built-in | `insert-last-word`, already bound and already working. No change. |
| 14 | Recursive globbing | built-in | `**/` works natively; add `EXTENDED_GLOB`. See dropped list for `GLOB_STAR_SHORT`. |
| 17 | Sensible defaults | built-in | `NO_BEEP`, `INTERACTIVE_COMMENTS` (both on), plus `NO_FLOW_CONTROL`, `ALWAYS_TO_END`, `COMPLETE_IN_WORD`, `AUTO_LIST`, `AUTO_MENU`. Remove `CORRECT`. |

**History change (#7), agreed:** `SHARE_HISTORY` interleaves other sessions' commands into your
Up-arrow live. Across many tmux panes that gets busy. Replacing it with `INC_APPEND_HISTORY_TIME`
means each pane's Up-arrow stays its own session's history while everything still lands in the
shared file — closer to how fish actually behaves.

### Dropped, and why

| # | Feature | Why |
|---|---|---|
| 8 | **Abbreviations** (`gco` + space → `git checkout`) | **Skipped entirely** (agreed). It rebinds the space key and must load before syntax highlighting, with edge cases in incremental search, bracketed paste and multi-line buffers. Plain aliases cover most of the value with zero keybinding risk. Dropping it is what makes phase 1 widget-free. |
| 10 | True `prevd`/`nextd` forward-history | zsh's `pushd` is a stack, not a back/forward cursor. Parity needs a custom ring plus mutable index state in a `chpwd` hook — a classic source of "why is my shell in the wrong directory". Built-in stack covers most of the value at no risk. |
| 14 | `GLOB_STAR_SHORT` | Changes what `**` means **globally**, including in sourced scripts — a semantic change for a small convenience. `**/` already works. |
| 15 | Command-not-found package suggestions | Real parity needs a package index (`homebrew/command-not-found` tap). Without it, the handler only tells you to run `brew search`, which you already know. |
| 16 | Terminal title | **You are always in tmux.** The tmux-safe design only set titles *outside* tmux, so it would never fire; the in-tmux version risks fighting your `automatic-rename-format`. Rule 2 settles it. |

### Honest gaps in what remains

- **Completion descriptions (#3)** — fish shows a description per candidate, universally. zsh shows
  them per *group*, and per-item only where the completer supplies them (`git`, `systemctl` do;
  many don't). This is the largest remaining gap and there is no fix within the constraints.
- **Syntax highlighting (#2)** — z-sy-h re-highlights the whole buffer per keystroke, so it lags
  fish noticeably on very long lines. `fast-syntax-highlighting` solves it but is a third plugin.
- **Directory history (#10)** — stack, not back/forward. Covered above.

---

## 3. Third-party dependencies

Per rule 4, the installer lives in `zsh/`:

```
zsh/install-plugins.sh      # clones + pins zsh-autosuggestions and zsh-syntax-highlighting
```

`scripts/install_zsh.sh` calls it, so `./install.sh` still does everything in one pass.
**This diverges from the `scripts/install_*.sh` convention** every other tool follows — flagging
it once so it isn't a surprise later; following your instruction regardless.

- Clone target `~/.config/zsh/plugins/`, mirroring how `install_tmux.sh` clones tpm.
- **Pinned to tags** in a single `ZSH_PLUGIN_PINS` array at the top, so updates are a deliberate
  one-line edit. Re-running `./install.sh` fetches and checks out the pin.
- **Not submodules** — `install.sh` has no submodule handling, and a plain clone of the dotfiles
  repo would silently produce a broken shell.
- Keep the existing `$HOMEBREW_PREFIX/share` → `/usr/share` lookup as a **fallback** if the clone
  directory is missing, so a half-installed machine still gets a working shell.

**fzf** stays (agreed). It is a third external dependency, technically outside the two-plugin
budget, but it is already installed and already sourced today — keeping it is the zero-change,
most-stable option. Worth a line in the README noting it as a soft dependency.

---

## 4. File layout — one file, not eleven

**Revised.** Earlier revisions proposed splitting `.zshrc` into an `rc.d/` directory of eleven
files. I drafted the finished config to measure it, and the split is not justified:

| | |
|---|---|
| Current `.zshrc` | 93 lines |
| **Finished config, everything in §2** | **237 lines** — 102 code, 94 comment, 41 blank |
| Largest section | keybindings, ~40 lines |

Only **102 lines of actual code**; the rest is the `#===== FEATURE n =====` banners and the
"why" comments this repo already favours. At that size a loader, eleven files, a new symlink and
a filename-encoded ordering contract are pure overhead.

It is also *less* stable, which matters more here. The one real correctness constraint in this
config is **load order** — `brew shellenv` must precede `compinit` (it prepends brew's
`site-functions` to `fpath`), and syntax-highlighting must come last (it wraps every widget that
exists when it loads). In a single file that ordering is plain top-to-bottom and visible on
screen. Split across eleven files it lives in numeric filename prefixes, where a later rename or
an added file breaks it silently.

So: **keep `zsh/.zshrc` as one file**, organised with section banners:

```
PATH → Options → History → Completion → Directory stack → Keybindings
     → Aliases → tmux → fzf → Plugins → Prompt
```

That order *is* the dependency order, top to bottom.

```
zsh/
  .zshenv              # unchanged — sets ZDOTDIR
  .zshrc               # 163 lines, section-banner organised
  install-plugins.sh   # clone + pin the two plugins
```

**Install change:** none to the symlinking — `scripts/install_zsh.sh` keeps its existing
`link_config` lines unchanged, and only gains a call to `zsh/install-plugins.sh`. The
file-by-file symlink comment stays true and no new symlink is introduced.

**Revisit if** the file passes ~400 lines, or if sections ever need conditional loading
(per-OS, per-host). Neither applies today.

A full draft is at `scratchpad/zshrc-single-draft.zsh` (parses clean under `zsh -n`); it is a
sizing exercise, not deployed.

---

## 5. Verification

**tmux safety check (rule 2), before and after.** Nothing in this plan emits an escape sequence,
so this should be a no-op — but it gets checked, not assumed:

- window names still follow `automatic-rename-format`, including the Claude Code `claude` case
- status bar still refreshes on `cd` (the `75-tmux.zsh` hook)
- gitmux pill still renders inside a repo
- `prefix + r` still reloads cleanly

**Feature test** — `tests/test-zsh-fishlike.sh`, in the existing bash style, covering the
non-interactive parts: `setopt` state, `zstyle -L` output, and `bindkey` targets for each key.

**Manual once-over** for the genuinely interactive parts: menu navigation and colour, suggestion
greyness and Alt-Right partial accept, Up-arrow prefix filtering, Ctrl-R, Alt-H man pages,
Ctrl-X Ctrl-E.

**No startup regression test** — dropped per rule 3.

---

## 6. Remaining risks

Short, now that the optimisations and the custom widgets are gone.

- **Alt-key bindings are terminal-specific.** Alacritty sends `^[[1;3C` for Alt-Right; other
  terminals send `^[^[[C` or nothing. We bind both and guard with `terminfo`. I can only verify
  Alacritty on this machine — if you use another terminal anywhere, Alt-Right may need a tweak.
- **`run-help` needs `unalias run-help`.** zsh aliases it to `man` by default; forgetting the
  unalias silently gives plain `man` instead of the subcommand-aware version.
- **The file restructure risk is now gone** — §4 keeps one file, so there is no loader, no glob,
  no new symlink and no filename-encoded ordering contract. Revert is one `git checkout`.
- **`INC_APPEND_HISTORY_TIME` is a real behaviour change** — a command run in one pane no longer
  appears in another pane's Up-arrow until a new shell starts there. That is the intent, but it
  will feel different on day one.

### Decisions — all resolved

| | Decision |
|---|---|
| Startup target | **Not a priority.** All optimisations dropped. |
| `compinit` | Full audit retained — no staleness risk. |
| `brew shellenv` | Plain `eval` retained — no hard-coded prefix. |
| fzf | **Kept.** |
| Abbreviations | **Skipped entirely.** |
| History | **`INC_APPEND_HISTORY_TIME`**, not `SHARE_HISTORY`. |
| `setopt CORRECT`, `_approximate`, `_correct` | **Dropped.** |
| `EDITOR` | **Stays `vim`** — not changing something that works. |
| `.zprofile` | Recommend deleting as redundant; **not touched without your word.** |

Ready to implement on your go-ahead.
