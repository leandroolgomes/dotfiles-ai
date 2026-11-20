# /dream: learn from recent sessions across projects

## Intent

`/learn` fixes one session that went wrong. Nothing looks across sessions and projects, and Claude Code memory
is siloed per project, so a lesson learned in one repo never reaches another. `/dream` reads the recent
sessions from every project, finds what keeps recurring, and turns each pattern into a skill or rule, but only
after the user has seen exactly what will be created and approved it.

## Goals

- Find patterns that recur across sessions, and especially across projects: repeated corrections, the same
  failure mode, a workflow done by hand again and again.
- Turn each approved pattern into a durable artifact, on the `/learn` ladder: ban pattern or check command,
  skill, or rule.
- Show the full change before writing anything, then write it with a test and prove it.

## Where learning goes: the user's own layer

`/dream` is a skill shipped by this repo and runs on the machine of whoever installed it. For that person the
clone is the install source: they keep it updated with `git pull`. What `/dream` learns is about them, so it
belongs in their own layer, never in the installed files. `~/.claude/CLAUDE.md`, `hooks/`, `settings.json` and
the shipped skills are symlinks into the clone; writing to them would mix personal lessons into the shipped
config and conflict with the next update. `/dream` resolves every target path (`realpath`) and refuses any that
lands inside the clone. It writes only to the user's layer, which the shipped hooks and Claude Code already load:

| Fix | Destination | Loaded by |
|---|---|---|
| Ban pattern | `~/work-context/rules.d/learned.rules` | `ban-patterns.sh` (already reads `rules.d/*.rules`) |
| Command that counts as a check | `~/work-context/rules.d/check-commands.txt` | `require-checks.sh` |
| Procedure / workflow | `~/.claude/skills/<name>/` as a real directory (never through a symlink) | Claude Code, all projects |
| Judgment rule | `~/.claude/rules/<topic>.md` | Claude Code user-level rules, all projects |

`~/work-context` is the private layer the hooks already read (`$WORK_CONTEXT` overrides it); `/dream` creates
the folders it needs there. A fix that needs a new hook script or a `settings.json` change can't live in the
user's layer: `/dream` shows it as a suggestion (something to propose upstream, or to make with `/learn` when
working on the repo) and writes nothing.

## Non-goals

- No schedule or background run (manual first; a scheduled detector may come later once the output is trusted).
- No curating per-project memory files (merging, pruning). Only skills and rules.
- No commits.

## Anti-goals

- A one-off event becomes a rule. A pattern needs at least 2 occurrences, with evidence quoted for each.
- Personal lessons end up in the installed dotfiles, where they conflict with updates (see below).

## Approaches

- **A. Scheduled detector, then `/learn` builds the fix**: nightly `bin/dream` writes candidates to agent-inbox.
- **B. Scheduled detector that also drafts the fix**: leaves a branch with the change and its test.
- **C. Manual `/dream` skill**: picked. The user runs it and sees and approves everything in the conversation.
  It is the simplest way to learn what good output looks like before automating. A and B can build on it later.

## Design

`claude/skills/dream/SKILL.md`, user-invoked (`disable-model-invocation: true`), `/dream [DAYS]`:

1. **Collect.** List the top-level transcripts in `~/.claude/projects/*/*.jsonl` changed in the last DAYS
   (default 7). Skip subagent transcripts and temp or scratchpad projects (`-private-tmp-*`, `-private-var-*`).
   Compress each one with `claude/skills/learn/scripts/digest.sh <path>` instead of reading the raw JSONL.
2. **Find patterns.** Use the failure-mode table in `/learn`, plus "repeated manual workflow", which points
   to a skill. Keep only patterns seen 2+ times. Rank them by how many projects they appear in, then by count.
3. **Check what already exists.** Drop or downgrade patterns that the current hooks, ban-pattern rules,
   skills, CLAUDE.md or `~/work-context/` already cover. If an existing rule failed to stop a pattern, report
   that rule as the thing to strengthen.
4. **Show candidates.** For each one: the pattern, quoted evidence (project, session id, the moment), the
   chosen fix and why not a stronger one, and the local destination from the table above. The user picks
   which ones to pursue.
5. **Show the exact change** for each picked candidate: the full new file or diff with its absolute path, plus
   how it will be proven. Wait for an explicit OK.
6. **Write and prove**: write only to the approved local path, then show it catching the original case (e.g.
   feed the quoted command to `ban-patterns.sh` and see it block; for a skill, an eval case next to it). Don't
   commit anything.

The `/dream` skill itself ships in the repo (`claude/skills/dream/`, linked by the installer like the others).
It also gets a README row and one eval in `claude/skills/dream/evals/`. The eval feeds
a fixture where the same correction appears in two projects, and checks that `/dream` proposes it, targets a
local path, and writes nothing before approval.

## Left to the builder

- The exact prompt wording for finding patterns, and how it handles a large digest volume (e.g. a limit on
  sessions per project).
- Whether "collect" is an inline shell loop in SKILL.md or a small `scripts/collect.sh`.
