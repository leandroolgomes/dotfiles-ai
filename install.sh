#!/usr/bin/env bash
# Installs this dotfiles repo: packages (Brewfile) + symlinks into $HOME.
# Idempotent. Existing files are moved to ~/.dotfiles-backup/<timestamp>/ first.
# Usage: ./install.sh [--dry-run] [--no-packages]
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DRY=0; PACKAGES=1; BREW_FAILED=0
for a in "$@"; do case "$a" in --dry-run) DRY=1;; --no-packages) PACKAGES=0;; esac; done

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
run() { if ((DRY)); then echo "[dry-run] $*"; else "$@"; fi; }

# link <repo-relative source> <absolute target>
link() {
  local src="$DOTFILES/$1" dst="$2"
  [[ -e "$src" ]] || { echo "missing $src"; return 1; }
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then return; fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    # keep the path relative to $HOME so same-named files (settings.json, config, ...) never collide
    local rel="${dst#"$HOME"/}"
    run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"; run mv "$dst" "$BACKUP_DIR/$rel"
    log "Backed up $dst -> $BACKUP_DIR"
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  log "Linked $dst -> $src"
}

if ((PACKAGES)); then
  [[ "$(uname)" == "Darwin" ]] || { echo "macOS only (Homebrew)."; exit 1; }
  command -v brew >/dev/null || { echo "Install Homebrew first: https://brew.sh"; exit 1; }
  log "Installing packages from Brewfile"
  # brew bundle tries every entry but exits non-zero if any fail; don't abort the whole install for that.
  run brew bundle --file="$DOTFILES/Brewfile" || { BREW_FAILED=1; echo "WARNING: some Brewfile packages failed (see output above); continuing."; }
fi

link ghostty/config            "$HOME/.config/ghostty/config"
link tmux/tmux.conf            "$HOME/.config/tmux/tmux.conf"
link starship/starship.toml    "$HOME/.config/starship.toml"
link mise-global/config.toml           "$HOME/.config/mise/config.toml"
link nvim                      "$HOME/.config/nvim"
link atuin/config.toml         "$HOME/.atuin/config.toml"
link git/gitconfig             "$HOME/.gitconfig"
link git/ignore                "$HOME/.config/git/ignore"
link claude/settings.json      "$HOME/.claude/settings.json"
link claude/CLAUDE.md          "$HOME/.claude/CLAUDE.md"
link claude/hooks              "$HOME/.claude/hooks"
link claude/agents             "$HOME/.claude/agents"
link claude/skills/commit      "$HOME/.claude/skills/commit"
link vscode/settings.json      "$HOME/Library/Application Support/Code/User/settings.json"
link ssh/config                "$HOME/.ssh/config"

# tuios rewrites its own config (set-config, hooks), so seed it once instead of symlinking.
TUIOS_CFG="$HOME/Library/Application Support/tuios/config.toml"
if [[ ! -e "$TUIOS_CFG" ]]; then
  run mkdir -p "$(dirname "$TUIOS_CFG")"; run cp "$DOTFILES/tuios/config.toml" "$TUIOS_CFG"
  log "Seeded $TUIOS_CFG"
fi

# ~/.zshrc stays yours; we only add one line that sources the repo's zsh/zshrc.
MARK="# dotfiles: $DOTFILES/zsh/zshrc"
if ! grep -qF "$MARK" "$HOME/.zshrc" 2>/dev/null; then
  log "Adding source line to ~/.zshrc"
  if ((DRY)); then echo "[dry-run] append to ~/.zshrc"; else
    [[ -f "$HOME/.zshrc" ]] && { mkdir -p "$BACKUP_DIR"; cp "$HOME/.zshrc" "$BACKUP_DIR/.zshrc"; }
    printf '\n%s\n[ -f "%s/zsh/zshrc" ] && source "%s/zsh/zshrc"\n' "$MARK" "$DOTFILES" "$DOTFILES" >> "$HOME/.zshrc"
  fi
fi

# VS Code extensions (skipped if the `code` CLI is not on PATH)
if command -v code >/dev/null; then
  while read -r ext; do [[ -n "$ext" ]] && run code --install-extension "$ext" --force >/dev/null; done < "$DOTFILES/vscode/extensions.txt"
fi

TPM="$HOME/.tmux/plugins/tpm"
[[ -d "$TPM" ]] || run git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM"
if ((DRY)); then echo "[dry-run] $TPM/bin/install_plugins"; elif [[ -x "$TPM/bin/install_plugins" ]]; then "$TPM/bin/install_plugins" || true; fi

log "Optional: review and run ./macos/defaults.sh for macOS preferences."
((BREW_FAILED)) && echo "WARNING: some Brewfile packages failed. Re-run: brew bundle --file=\"$DOTFILES/Brewfile\"" >&2
log "Done. Open Ghostty and run tmux (prefix is Ctrl-a; Ctrl-a then I fetches plugins if needed)."
