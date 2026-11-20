---
name: dream
description: Learn from recent sessions across all projects. Finds patterns that recur across sessions and projects and, after the user approves the exact change, writes a skill or rule into the user's own layer. Use when the user says /dream, optionally with a number of days and --root DIR.
disable-model-invocation: true
---

`/learn` fixes one session. `/dream` looks across many, in every project, for what keeps coming back: the
same correction, the same failure, the same workflow done by hand. A lesson seen once is an anecdote; only
patterns with 2+ occurrences become rules. Nothing is written until the user has seen the exact change.

Usage: `/dream [DAYS] [--root DIR]` (default 7 days, `~/.claude/projects`). Scripts are in
`~/.claude/skills/dream/scripts/`.

## Where lessons go: the user's layer, never the dotfiles

The installed dotfiles (`~/.claude/CLAUDE.md`, `hooks/`, `settings.json`, the shipped skills) are symlinks into
the clone the user installed from and updates with `git pull`. Personal lessons never go there.

| Fix | Destination | Loaded by |
|---|---|---|
| Ban pattern (text in a command or edit) | `$WORK_CONTEXT/rules.d/learned.rules` (default `~/work-context`), format of `~/.claude/hooks/ban-patterns.rules` | `ban-patterns.sh` |
| Command that counts as a check | `$WORK_CONTEXT/rules.d/check-commands.txt` | `require-checks.sh` |
| Procedure or workflow | `~/.claude/skills/<name>/SKILL.md` (a real folder) | Claude Code, all projects |
| Judgment rule | `~/.claude/rules/<topic>.md` | Claude Code, all projects |

Run `scripts/target-ok.sh <path>` on every destination before showing it and again right before writing; if it
refuses, pick another destination. A fix that needs a new hook script or a `settings.json` change is a
suggestion only (to propose upstream, or to make with `/learn` while working on the dotfiles repo): show it,
write nothing.

## 1. Collect

`scripts/collect.sh --days DAYS [--root DIR]` lists `project<TAB>path`, newest first. Nothing listed: say so and
stop. Read each one through `~/.claude/skills/learn/scripts/digest.sh <path>`, never the raw JSONL; open the
raw transcript only around a moment you will quote.

## 2. Find patterns

Look for: user corrections ("no", "I said", "always", "never"), the failure modes in the table of
`~/.claude/skills/learn/SKILL.md`, and the same multi-step workflow done by hand in several sessions (a skill
candidate). Group occurrences that are the same lesson. Keep only groups with 2+ occurrences; rank by the
number of projects, then by count. Say what you dropped for having one occurrence.

## 3. Check what already covers it

Before proposing, read what is loaded today: `~/.claude/CLAUDE.md`, `~/.claude/rules/`, `~/.claude/skills/`,
`~/.claude/hooks/ban-patterns.rules`, `$WORK_CONTEXT/rules.d/`, and the project's own CLAUDE.md if relevant.
Covered and it never recurred: drop it. Covered but it kept happening: the candidate is to make that rule
stronger (a soft rule that keeps breaking becomes a ban pattern or a hook suggestion).

## 4. Show the candidates

One block per candidate, strongest first:
- the lesson in one line
- evidence: each occurrence as `project · session id · quoted user words / agent action`
- the fix and why not a stronger one (ladder from `/learn`: ban pattern or check > skill > rule)
- the destination from the table as an absolute path, already passed through `target-ok.sh`
- the proposed content itself (the exact line or file, no `...`)

A ban pattern is a case-insensitive extended regex with no lookahead. Before proposing one, test it with
`grep -Ei` against the commands in the evidence: it must match the bad ones and not the corrected ones. If the
regex can't tell them apart, use a weaker rung instead of shipping a pattern that blocks the right command.

Ask which ones to pursue. Stop here until the user answers.

## 5. Show the exact change

For each chosen candidate: the absolute path, the full new file or the exact lines appended, and how it will be
proven. Ask for an explicit OK. No OK, no write.

## 6. Write and prove

Run `target-ok.sh` on the path again, then write only that file (create its folder if needed). Prove it:
- ban pattern: feed a quoted command from the evidence to the hook and show it blocked:
  `jq -n --arg c '<command>' '{tool_name:"Bash",tool_input:{command:$c}}' | ~/.claude/hooks/ban-patterns.sh; echo "exit $?"`
- check command: show the line in `check-commands.txt`
- skill: add an eval case in `~/.claude/skills/<name>/evals/` (format in `bin/skill-eval` of the dotfiles) and
  say whether it was run
- rule: show the file and say that it loads in new sessions

Report what was written, where, and the proof. Never commit anything.
