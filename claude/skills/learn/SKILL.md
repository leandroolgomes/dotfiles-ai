---
name: learn
description: Turn an agent failure into a durable fix. Reads a session transcript, names the failure mode, and proposes the strongest enforcement that would have prevented it (lint/CI → hook → ban pattern → skill → CLAUDE.md), then writes it with a test. Use when the user says /learn, optionally with a session id, transcript path or a description of what went wrong.
disable-model-invocation: true
---

Every correction the user has to repeat is a missing rule. Soft rules (CLAUDE.md, skills) get forgotten;
hard rules (a failing check) don't. Pick the strongest layer that works.

## 1. Find the failure

- Get a compact timeline: `~/.claude/skills/learn/scripts/digest.sh [SESSION_ID|PATH]` (no argument: latest
  session for this directory; `--list` to pick one). Read the full transcript only around the moment that matters.
- If the user described the problem, find where it happens. If not, look for: user corrections ("no",
  "that's wrong", "I told you"), repeated failing commands, `ERROR` lines followed by a confident claim,
  edits with no check afterwards, claims of "done" or "fixed" with no evidence.
- Quote the moment: the user's words, the agent's action, the tool output it ignored.

## 2. Name the failure mode

Pick one (or write a new one in the same style):

| Mode | Looks like |
|---|---|
| guessed instead of reading | claimed a cause without reading the code or logs that would show it |
| unverified done | said done/fixed without running anything that observes the behavior |
| ignored tool output | an error or warning was in the output and the next step acted as if it wasn't |
| cheated a check | skipped/disabled a test or linter, loosened an assertion, `--no-verify` |
| scope creep | changed things nobody asked for |
| missed a capability | didn't use an available tool or skill (browser, subagent, a project script) |
| wrong environment assumption | assumed network, credentials, OS or paths that weren't there |
| repeated a known mistake | something CLAUDE.md, a skill or `~/work-context` already covers |

## 3. Choose the strongest fix that works

Go down this ladder and stop at the first rung that can catch it:

1. **Make it impossible or a hard failure in the project**: types, a lint rule, a compiler setting, a test,
   an import-boundary check. Best, but belongs to the project. Propose it; don't change a company repo's CI
   without the user saying so.
2. **A Claude hook** (this dotfiles repo, `claude/hooks/`): `ban-patterns.rules` for a text pattern in edits or
   commands, `require-checks.sh` for "must run X before stopping", or a new hook for anything else.
3. **A skill or a skill change**: for a procedure the agent didn't know (how to verify, how to debug this kind
   of system). If the project lacks a way to run the app, suggest `/verify-setup`.
4. **One line in CLAUDE.md**: only for judgment that nothing above can check. Say why it can't be harder.

**Where it goes:** generic → this dotfiles repo (public: no company names, hosts, tools or code).
Company-specific → `~/work-context/`: `rules.d/*.rules` (same format as `claude/hooks/ban-patterns.rules`),
`rules.d/check-commands.txt` (extra commands that count as checks), `incidents/<date>-<slug>.md` (one rule per
incident, which `/hypothesis` also reads), `standards/`.

## 4. Propose, then write

1. Show: the quoted moment, the failure mode, the chosen rung and why not a stronger one, and the exact change
   (diff or new file). Wait for the user's OK.
2. Write it **with a test**: a line in `claude/hooks/tests/*.cases` for a ban pattern or `block-dangerous`
   rule, a case in `claude/hooks/tests/run.sh` for hook logic, an eval case in
   `claude/skills/<skill>/evals/` for a skill change (see `bin/skill-eval`).
3. Prove it: run `bin/dotfiles-check` (or the new test) and show it catching the original failure.
4. Don't commit. Report what changed and how it was proven.
