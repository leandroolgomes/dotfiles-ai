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
| | herdr, alternative agent multiplexer (seeded once, not linked); see below | `herdr/config.toml` |
| Shell | zsh (zoxide, atuin, mise, fzf, eza), sourced from `~/.zshrc` | `zsh/zshrc` |
| | Starship prompt | `starship/starship.toml` |
| | atuin history | `atuin/config.toml` (linked to `~/.atuin/`) |
| Editor | nvim (LazyVim) | `nvim/` |
| | VS Code | `vscode/settings.json`, `vscode/extensions.txt` |
| Git | git (+ delta), global ignore | `git/gitconfig`, `git/ignore` |
| | SSH (config only, never keys) | `ssh/config` |
| Runtimes | mise (global Go, Node) | `mise-global/config.toml` |
| AI | Claude Code | see below |
| | `review-fanout`: multi-agent code review in tuios or herdr panes | `bin/review-fanout` (linked to `~/.local/bin/`) |
| | `agent-inbox`: one queue of what needs you (blocked agents, reviews, red CI); pluggable sources | `bin/agent-inbox`, `inbox/` (see `inbox/README.md`) |
| | `skill-eval`: unit tests for skills, judged by a different model | `bin/skill-eval`, `claude/skills/*/evals/` |
| | `issue-triage`: unattended agent that triages new GitHub issues into the inbox (opt-in) | `bin/issue-triage` |
| | `agent-metrics`: weekly interrupts, rejections, hook blocks and tokens from your transcripts | `bin/agent-metrics` |
| Repo checks | `dotfiles-check`: shellcheck, settings, frontmatter, hook tests, gitleaks; runs on pre-commit and install | `bin/dotfiles-check`, `.githooks/` |
| macOS | Opt-in preferences (not run by the installer) | `macos/defaults.sh` |
| Packages | Homebrew formulae, casks and taps | `Brewfile` |

### Claude Code (`claude/`)

| File | Purpose |
|---|---|
| `CLAUDE.md` | Global instructions (English, concise; safety rules, environment, stack, working principles). Each rule is tagged with the hook that enforces it, if any |
| `settings.json` | Model, statusline, enabled plugins, hooks (notifications, tuios, herdr, safety) |
| `hooks/block-dangerous.sh` | Blocks destructive Bash commands (`rm -rf ~`, force-push, `DROP TABLE`, `curl \| sh`, ...) |
| `hooks/gitleaks-commit.sh` | Runs `gitleaks` on staged changes before `git commit` |
| `hooks/ban-patterns.sh` + `.rules` | Blocks edits that add lint suppressions, skipped/focused tests or comments that narrate history, and `git add -A`/`--no-verify`. Only new matches block |
| `hooks/require-checks.sh` | Stop hook: if code changed and no test/lint/build/verify ran after the last edit, blocks once and asks for the checks |
| `hooks/format-on-edit.sh` | After each edit, runs the repo's own formatter and linter (gofmt/goimports, prettier, eslint, ruff, shellcheck...) and returns errors |
| `hooks/tests/` | Table-driven tests for every hook (`run.sh`, `*.cases`) |
| `agents/code-reviewer.md` | Read-only reviewer for recent diffs |
| `agents/test-runner.md` | Runs tests and returns only failures |
| `skills/commit/` | `/commit`: one commit per concern |
| `skills/verify-setup/` | `/verify-setup`: creates a project's `verify` skill (start, doctor, drive, stop by PID, evidence that survives cleanup) and `FEATURE_MAP.md` so agents run the real app and prove changes; `refresh` keeps it current |
| `skills/blast-radius/` | `/blast-radius`: what a change breaks outside its diff; proves the one fact it is safe because of by running code, and reports instead of fixing |
| `skills/learn/` | `/learn`: reads a session transcript, names the failure mode and turns it into the strongest fix (hook, ban pattern, skill, CLAUDE.md) with a test |
| `skills/dream/` | `/dream`: reads recent sessions across all projects, finds what keeps recurring, and after you approve the exact change writes a skill or rule into your own layer (`~/.claude/rules`, `~/.claude/skills`, `$WORK_CONTEXT/rules.d`), never into this repo |
| `skills/hypothesis/` | `/hypothesis` (Stop hook in `hooks/proof-gate.sh`): you write your guess, risk and proof first; the agent works to that finish line and reports its decisions. `/hypothesis close` logs calibration to `~/work-context/` |

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

### Multi-agent review (`bin/review-fanout`)

Fans a code review out to several agents, each in its own tuios or herdr pane (visible in the tuios
agents tab or the herdr sidebar, where you answer them if they ask), waits for all of them, then merges the reviews into one report with
Claude Haiku.

```sh
review-fanout --reviewers claude:sonnet-5.5,codex:sol-6.1           # review the current directory
review-fanout --reviewers claude:opus,codex --code-path ~/dev/api --focus "the retry logic"
```

- Supported reviewers: `claude[:model]`, `codex[:model]`. `sonnet-5.5` becomes `claude-sonnet-5-5`.
- Each finding needs proof from a run: the command, its output and the output it should have given.
  The report lists findings without one under "Unproven". Reviewers keep repros in the output directory
  and must leave the code as they found it: Claude may run any Bash command (`block-dangerous` still
  applies); Codex runs in the output directory with a `workspace-write` sandbox.
- Codex starts with the output directory trusted. Claude asks to trust a directory it has not seen
  before; answer it once in the agents tab.
- Output: one `<reviewer>.md` per agent plus `report.md` in `$TMPDIR/review-fanout/<dir>-<timestamp>`
  (or `--out`). The script prints the report path. Reviewer panes stay open for follow-up questions.
- Options: `--mux tuios|herdr` (default: the multiplexer you run it from, else `$AGENT_MUX`, else tuios),
  `--session` (tuios session or herdr workspace label; default: current tuios session), `--timeout`
  minutes (default 30). herdr needs a running server (`herdr`).

### Choosing tuios or herdr

Both are installed; use whichever you launch. Scripts pick the one they run in (`HERDR_ENV` /
`TUIOS_SESSION`); set `AGENT_MUX=herdr` in your shell to make herdr the default from a plain terminal.

| | tuios | herdr |
|---|---|---|
| Agent state | Claude hooks (`tuios agent-hook`) | Screen detection; the Claude hook only reports the session id so agents resume after a restart |
| Inbox source | `inbox/sources.d/tuios` | `inbox/sources.d/herdr` |
| Agent control | `tuios ask-agent`, `get-agent-state` | `herdr agent prompt --wait`, `agent wait`, `agent read`; `herdr --skill` prints the reference |
| Extras | | Git worktree workspaces, `herdr --remote ssh://host`, detach with `ctrl+b q` |

- `claude/hooks/herdr-agent-state.sh` is generated by herdr (`herdr integration install claude`) and
  committed here with a `$HOME` path. Don't rerun that command: it would add a second entry with your
  absolute home path to `settings.json`. After a herdr update, check `herdr integration status`; if it
  says outdated, regenerate into a scratch dir
  (`CLAUDE_CONFIG_DIR=$(mktemp -d) herdr integration install claude`) and copy the hook over.
- Don't run tmux inside a herdr pane: herdr can no longer see the agent.

### Work context (`~/work-context/`, private)

This repo is public and generic. Everything about your company (conventions, incidents, internal
tools, rules about what needs you) lives in `~/work-context/`, a private folder that is never committed
here. Keep it in a private git repo or other company-approved storage.

```
~/work-context/
  inbox/            config.toml, rules.toml, sources.d/   ← agent-inbox (agent-inbox init creates it)
  standards/        team conventions                       ← /hypothesis proposes proof items from these
  incidents/        one rule per postmortem                ← /hypothesis proposes proof items from these; /learn adds
  rules.d/          *.rules, check-commands.txt            ← company ban patterns and check commands for the hooks
  hypotheses/       closed HYPOTHESIS.md files             ← /hypothesis close
  calibration.md    one line per closed hypothesis         ← /hypothesis close
```

Nothing here is required: each feature works without it and uses whatever exists. Create `inbox/` with
`agent-inbox init` (or point `AGENT_INBOX_HOME` elsewhere); the `/hypothesis` parts are created as you use it.

Optional pattern, not set up by this repo: put the short context every agent should know in
`~/work-context/CORE.md` (team conventions, plus an index of which files to read for which code) and add
`@~/work-context/CORE.md` to your own `~/.claude/CLAUDE.md` so every session loads it.

### Agent inbox (`bin/agent-inbox`)

One queue of what needs you: agents blocked on you or finished, review requests, red CI, and any
source you connect later.

```sh
agent-inbox             # 🔴 needs you now · 🟡 today · ✅ done, ready to review · ⚪ FYI (counted)
agent-inbox --all       # also list FYI items
agent-inbox doctor      # which sources are connected, and the exact command to fix the rest
agent-inbox init        # create the private overlay in ~/work-context/inbox/
```

- Built-in sources: `tuios` (blocked and finished agents in every session), `herdr` (the same for
  the herdr CLI server), `herdr-app` (the same for the herdr app, via `herdr-core`) and `github` (review
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
   what I did" and "Decisions you didn't make". The `proof-gate.sh` Stop hook (in the skill's `hooks/`) blocks "done" while
   that is missing; it nudges once per stop, so the agent can still stop to ask you something.
4. `/hypothesis close` records whether your guess and risk were right. Over time `calibration.md` shows where
   your instincts are reliable.

## Enforcement layers

Rules only hold if something checks them. From strongest to weakest:

| Layer | Where | Fails how |
|---|---|---|
| Types, compiler, lint, tests, CI | each project (the company owns its CI) | build is red |
| Claude hooks | `claude/hooks/` here + `~/work-context/rules.d/` | the tool call or the stop is blocked |
| Skills | `claude/skills/`, a project's `.claude/skills/verify` | the agent may forget |
| CLAUDE.md | `claude/CLAUDE.md` | the agent may forget |

Hooks are the hard layer you carry between companies: they use each repo's own formatter, linter and test
commands, so they adapt to whatever CI the company has. Company-specific rules go in `~/work-context/rules.d/`:

```
~/work-context/rules.d/acme.rules            # scope<TAB>regex<TAB>message, same as claude/hooks/ban-patterns.rules
code	useEffect\(	useEffect is banned here; use the data hooks in src/data
~/work-context/rules.d/check-commands.txt    # extra commands that count as checks for require-checks (one regex per line)
acme-ci( |$)
```

The loop that keeps it growing: a review comment or a bad session → `/learn` (or the "Promote to rule" section of
`review-fanout`) → the strongest rule that works, with a test → `dotfiles-check`. Skills get the same treatment:
`skill-eval --skill X --min-score 9` scores them on eval cases, and you edit until they pass.

Disable a hook for one session: `CLAUDE_REQUIRE_CHECKS=0` or `CLAUDE_FORMAT_ON_EDIT=0`.

### Is it working? (`bin/agent-metrics`)

Reads `~/.claude/projects/**/*.jsonl` and prints, per week, how often you had to step in (interrupts, rejected
tool calls), how often each hook and ban-patterns rule blocked, and tokens. `claude -p` runs (`issue-triage`,
`skill-eval`) are counted apart. Use it to see whether a rule from `/learn` or `/dream` changed anything, and to
drop hooks that never fire.

```sh
agent-metrics               # last 8 weeks
agent-metrics --weeks 12 --json
```

To check a judgment rule, add the correction you kept typing to `~/work-context/metrics/watch.tsv`
(`label<TAB>regex<TAB>since`, e.g. `blind-staging	git add -A	2026-11-20`); the report shows how often your prompts
match it per session before and after that date. Claude Code deletes transcripts after `cleanupPeriodDays`
(set to 365 in `settings.json`), and each run also keeps its weekly counts in `~/.local/state/agent-metrics/`.

### Unattended triage (`bin/issue-triage`, opt-in)

```sh
issue-triage run --repo me/api --dry-run                    # what it would pick up
issue-triage run --repo me/api --label bug --limit 3        # triage now; reports appear in agent-inbox
issue-triage schedule --every 60 -- run --repo me/api       # LaunchAgent, runs outside tuios
issue-triage ack me/api#42                                  # done reading a report
```

For each new issue it runs `claude -p` in a clean clone, reproduces with the repo's `verify` skill if there is one,
checks whether the default branch already fixed it, and writes a report. It never changes code and only comments
on the issue with `--comment`. Turn it on after you trust the `verify` skill: watch a few local runs first.

## Install

```sh
git clone git@github.com:leandroolgomes/dotfiles-ai.git ~/dev/dotfiles-ai
cd ~/dev/dotfiles-ai
./install.sh --dry-run        # preview, changes nothing
./install.sh                  # packages + symlinks
./install.sh --no-packages    # symlinks only (skip brew bundle)
./install.sh --skip-checks    # link even if dotfiles-check fails (not recommended)
```

`install.sh` is idempotent and macOS-only. It:
1. Runs `brew bundle` on the `Brewfile` (unless `--no-packages`).
2. Runs `bin/dotfiles-check --quick` and stops if it fails, then points this repo's git hooks at `.githooks/`
   (pre-commit runs `dotfiles-check` and `gitleaks` on staged changes).
3. Symlinks each config into `$HOME`. Existing files are moved to `~/.dotfiles-backup/<timestamp>/` first.
4. Adds one line to `~/.zshrc` that sources `zsh/zshrc` (your `~/.zshrc` stays yours).
5. Seeds the tuios and herdr configs once (both rewrite their own file).
6. Installs VS Code extensions (if `code` is on PATH) and tmux plugins (TPM).

Optional, after reviewing it: `./macos/defaults.sh` for keyboard, Finder, Dock and screenshot preferences.

Because configs are symlinks, edit files here and changes apply immediately. Some tools
(Claude Code, tuios, VS Code) may rewrite their settings file in place or replace it; if a symlink
breaks, `git status` here will show it.

## Secrets

The repo is public, so nothing secret belongs in it: no SSH keys, tokens, `.env` files or auth files
(see `.gitignore`). Run `gitleaks dir .` before pushing.
