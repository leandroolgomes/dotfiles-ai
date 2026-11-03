# dotfiles-ai

Personal macOS terminal + AI-assisted dev setup, installed with one script.
Terminal part inspired by the video "I Tried Everything. This is the Best Terminal Setup"
(reference: https://github.com/omerxx/dotfiles).

## What's inside

| Area | Tool | Config |
|---|---|---|
| Terminal | Ghostty | `ghostty/config` |
| | tmux (+ sesh, SessionX, Floax, Catppuccin) | `tmux/tmux.conf` |
| | tuios (seeded once, not linked; sidebar editor = nvim) | `tuios/config.toml` |
| Shell | zsh (zoxide, atuin, mise, fzf, eza), sourced from `~/.zshrc` | `zsh/zshrc` |
| | Starship prompt | `starship/starship.toml` |
| | atuin history | `atuin/config.toml` (linked to `~/.atuin/`) |
| Editor | nvim (LazyVim) | `nvim/` |
| | VS Code | `vscode/settings.json`, `vscode/extensions.txt` |
| Git | git (+ delta), global ignore | `git/gitconfig`, `git/ignore` |
| | SSH (config only, never keys) | `ssh/config` |
| Runtimes | mise (global Go, Node) | `mise-global/config.toml` |
| AI | Claude Code | see below |
| macOS | Opt-in preferences (not run by the installer) | `macos/defaults.sh` |
| Packages | Homebrew formulae, casks and taps | `Brewfile` |

### Claude Code (`claude/`)

| File | Purpose |
|---|---|
| `CLAUDE.md` | Global instructions (English, concise; safety rules, environment, stack) |
| `settings.json` | Model, statusline, enabled plugins, hooks (notifications, tuios, safety) |
| `hooks/block-dangerous.sh` | Blocks destructive Bash commands (`rm -rf ~`, force-push, `DROP TABLE`, `curl \| sh`, ...) |
| `hooks/gitleaks-commit.sh` | Runs `gitleaks` on staged changes before `git commit` |
| `agents/code-reviewer.md` | Read-only reviewer for recent diffs |
| `agents/test-runner.md` | Runs tests and returns only failures |
| `skills/commit/` | `/commit` skill |

The hooks are guardrails against accidents, not a security boundary. Not versioned on purpose:
`~/.claude.json`, `settings.local.json`, history, projects, caches and tool-installed skills.

## Install

```sh
git clone git@github.com:leandroolgomes/dotfiles-ai.git ~/dev/dotfiles-ai
cd ~/dev/dotfiles-ai
./install.sh --dry-run        # preview, changes nothing
./install.sh                  # packages + symlinks
./install.sh --no-packages    # symlinks only (skip brew bundle)
```

`install.sh` is idempotent and macOS-only. It:
1. Runs `brew bundle` on the `Brewfile` (unless `--no-packages`).
2. Symlinks each config into `$HOME`. Existing files are moved to `~/.dotfiles-backup/<timestamp>/` first.
3. Adds one line to `~/.zshrc` that sources `zsh/zshrc` (your `~/.zshrc` stays yours).
4. Seeds the tuios config once (tuios rewrites its own file).
5. Installs VS Code extensions (if `code` is on PATH) and tmux plugins (TPM).

Optional, after reviewing it: `./macos/defaults.sh` for keyboard, Finder, Dock and screenshot preferences.

Because configs are symlinks, edit files here and changes apply immediately. Some tools
(Claude Code, tuios, VS Code) may rewrite their settings file in place or replace it; if a symlink
breaks, `git status` here will show it.

## Secrets

The repo is private, but nothing secret belongs in it: no SSH keys, tokens, `.env` files or auth files
(see `.gitignore`). Run `gitleaks dir .` before pushing.
