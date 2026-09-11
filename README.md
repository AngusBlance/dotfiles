# nvim

## Setup

On a fresh machine, the whole setup is:
```
git clone git@github.com:AngusBlance/dotfiles.git
./dotfiles/install.sh
```
The hook itself tries `afplay` → `paplay` → `aplay` → terminal bell, so it degrades gracefully on macOS, other Linux audio stacks, or a bare server with no player at all.