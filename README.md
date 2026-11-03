# dotfiles

Terminal setup inspired by the video "I Tried Everything. This is the Best Terminal Setup"
(reference: https://github.com/omerxx/dotfiles).

| Tool | Config |
|---|---|
| Ghostty | `ghostty/config` |
| tmux (+ sesh, SessionX, Floax, Catppuccin) | `tmux/tmux.conf` |
| Starship | `starship/starship.toml` |
| zsh (zoxide, atuin, mise, fzf, eza) | `zsh/zshrc` (sourced from `~/.zshrc`) |
| mise (global tool versions) | `mise-global/config.toml` |
| tuios (seeded once, not linked; sidebar editor = nvim) | `tuios/config.toml` |
| nvim (LazyVim) | `nvim/` |
| Claude Code (settings, hooks, plugins list) | `claude/settings.json` |
| git (+ delta, global ignore) | `git/gitconfig`, `git/ignore` |
| atuin | `atuin/config.toml` |
| VS Code (settings + extensions) | `vscode/` |
| SSH (config only, never keys) | `ssh/config` |
| macOS preferences (opt-in, not run by install) | `macos/defaults.sh` |
| Packages | `Brewfile` (includes tuios) |

## Install
```sh
./install.sh --dry-run   # preview
./install.sh             # packages + symlinks
```
Replaced files go to `~/.dotfiles-backup/`. Edit files in this repo; the symlinks pick changes up immediately.
