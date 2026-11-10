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
| `CLAUDE.md` | Global instructions (English, concise; safety rules, environment, stack, working principles) |
| `settings.json` | Model, statusline, enabled plugins, hooks (notifications, tuios, safety) |
| `hooks/block-dangerous.sh` | Blocks destructive Bash commands (`rm -rf ~`, force-push, `DROP TABLE`, `curl \| sh`, ...) |
| `hooks/gitleaks-commit.sh` | Runs `gitleaks` on staged changes before `git commit` |
| `agents/code-reviewer.md` | Read-only reviewer for recent diffs |
| `agents/test-runner.md` | Runs tests and returns only failures |
| `skills/commit/` | `/commit` skill |

#### Agentic SDLC with Superpowers

The [superpowers](https://github.com/obra/superpowers) plugin (`superpowers@claude-plugins-official`,
enabled in `settings.json`) adds a skill per SDLC phase. Claude loads each one automatically when the
phase starts; you rarely need to call them by hand.

```
spec -> plan -> isolate -> implement -> debug -> verify -> review -> ship
```

| Phase | Skill | What it does |
|---|---|---|
| Spec | `brainstorming` | Clarifies intent and requirements before any creative work or new feature |
| Plan | `writing-plans` | Turns a spec into a multi-step plan before touching code |
| Isolate | `using-git-worktrees` | Gives the work an isolated workspace (native tools or `git worktree`) |
| Implement | `test-driven-development` | Red-green-refactor: write the failing test before the implementation |
| | `executing-plans` | Runs a plan inline, in the current session |
| | `subagent-driven-development` | Runs a plan with independent tasks via subagents |
| | `dispatching-parallel-agents` | Fans out 2+ independent tasks to parallel agents |
| Debug | `systematic-debugging` | Root cause first (reproduce, hypothesize, confirm), then fix |
| Verify | `verification-before-completion` | Run the checks and read the output before claiming "done" |
| Review | `requesting-code-review` | Reviews work against requirements before merging |
| | `receiving-code-review` | Verifies feedback technically instead of agreeing blindly |
| Ship | `finishing-a-development-branch` | Decides how to integrate: merge, PR or cleanup |
| Meta | `writing-skills` | Creates and tests new skills |
| | `using-superpowers` | Teaches Claude how to find and use the skills above |
| | `diagnosing-superpowers` | Post-mortem for a session that went wrong |

Complements the local pieces: `/commit` for the commit step, the `code-reviewer` agent for read-only
reviews and `test-runner` for failure-only test output. The skill list follows upstream and may change.

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
