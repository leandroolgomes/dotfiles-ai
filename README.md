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
| | `agent-inbox`: one queue of what needs you (blocked agents, reviews, red CI); pluggable sources | `bin/agent-inbox`, `inbox/` (see `inbox/README.md`) |
| macOS | Opt-in preferences (not run by the installer) | `macos/defaults.sh` |
| Packages | Homebrew formulae, casks and taps | `Brewfile` |

### Claude Code (`claude/`)

| File | Purpose |
|---|---|
| `CLAUDE.md` | Global instructions (English, concise; safety rules, environment, stack, working principles) |
| `settings.json` | Model, statusline, enabled plugins, hooks (notifications, tuios, safety) |
| `hooks/block-dangerous.sh` | Blocks destructive Bash commands (`rm -rf ~`, force-push, `DROP TABLE`, `curl \| sh`, ...) |
| `hooks/gitleaks-commit.sh` | Runs `gitleaks` on staged changes before `git commit` |
| `hooks/hypothesis-proof-gate.sh` | Stop hook: with an active `HYPOTHESIS.md`, blocks "done" until each proof item has evidence and the report lists decisions |
| `agents/code-reviewer.md` | Read-only reviewer for recent diffs |
| `agents/test-runner.md` | Runs tests and returns only failures |
| `skills/commit/` | `/commit` skill |
| `skills/hypothesis/` | `/hypothesis`: you write your guess, risk and proof first; the agent works to that finish line and reports its decisions. `/hypothesis close` logs calibration to `~/work-context/` |

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

### Agent inbox (`bin/agent-inbox`)

One queue of what needs you: agents blocked on you or finished, review requests, red CI, and any
source you connect later.

```sh
agent-inbox             # 🔴 needs you now · 🟡 today · ✅ done, ready to review · ⚪ FYI (counted)
agent-inbox --all       # also list FYI items
agent-inbox doctor      # which sources are connected, and the exact command to fix the rest
agent-inbox init        # create the private overlay in ~/work-context/inbox/
```

- Built-in sources: `tuios` (blocked and finished agents in every session) and `github` (review
  requests, red CI on `main` for the repos in `config.toml`; GitHub Enterprise via `hosts`).
- Company sources (Jira, PagerDuty, internal tools) go in `~/work-context/inbox/sources.d/`, never in
  this repo. Start from `inbox/adapter-template`; a source is any executable answering `check` and `items`.
- `rules.toml` decides what counts as "needs me" (first match wins). Defaults: `inbox/rules.default.toml`.
- No credentials are stored: sources use your own CLI logins (`gh auth login`) or the Keychain.
- Contract and layout: `inbox/README.md`.

### Critical-thinking loop (`/hypothesis`)

Keeps you doing the thinking while the agent does the work: your guess comes first, proof is the
finish line, and you read the agent's decisions instead of the whole diff.

```
/hypothesis add DynamoDB support to the DLQ manager   # you answer: guess, biggest risk, what would change your mind, proof
/hypothesis status                                    # proof progress and decisions so far
/hypothesis close                                     # your verdict → ~/work-context/calibration.md
```

1. `/hypothesis <task>` asks for your answers first (no suggestions, to avoid anchoring), then proposes extra
   proof items you can check with a command, and writes `HYPOTHESIS.md` at the git root (globally git-ignored).
2. The agent works toward that proof and logs every decision you didn't specify, flagging contract changes with ⚠️.
3. Before stopping it fills `HYPOTHESIS.md`: evidence under each proof item (or `[!]` with a reason), "Hypothesis vs.
   what I did" and "Decisions you didn't make". The `hypothesis-proof-gate.sh` Stop hook blocks "done" while
   that is missing; it nudges once per stop, so the agent can still stop to ask you something.
4. `/hypothesis close` records whether your guess and risk were right. Over time `calibration.md` shows where
   your instincts are reliable.

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
