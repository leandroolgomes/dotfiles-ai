---
name: verify-setup
description: Create or refresh a project's verification skill (.claude/skills/verify/) and its FEATURE_MAP.md, so agents can run the real app and prove a change works instead of guessing. Use when the user says /verify-setup or /verify-setup refresh.
disable-model-invocation: true
---

Goal: an agent in this project can run the real thing (service, CLI, UI) and prove behavior, and can find
any user-facing feature from a vague report. Without this, the user is the verifier and the bottleneck.

Output, in the project (not in dotfiles):

```
<repo>/.claude/skills/verify/SKILL.md      how to start, drive, observe and stop the app (model-invocable)
<repo>/.claude/skills/verify/FEATURE_MAP.md   feature → how to reach it → how to check it → code
<repo>/.claude/skills/verify/scripts/       only if a step is too long for one command (start/stop/seed)
```

The `require-checks` Stop hook counts using the `verify` skill as a check.

## `/verify-setup`: create

1. **Find the app type and entry points.** Read the README, Makefile/justfile, package.json scripts, mise tasks,
   docker-compose, `cmd/` and `main` packages, CI config. Pick the recipe(s) from `recipes/` next to this file:
   `go-service.md`, `cli.md`, `web-playwright.md`. A repo can need more than one.
2. **Run it for real before writing anything.** Start the app the way the recipe says, hit one real path, read
   the logs, stop it cleanly. Every command you write in the skill must have been run once in this session.
   If a step needs something you can't get (credentials, a VPN, a paid service), stop and ask the user
   how they run it locally; don't invent a mock and call it verification.
3. **Build the feature map** from the code, not from guesses: routes/handlers, CLI commands, queue consumers,
   scheduled jobs, UI screens. Use `templates/FEATURE_MAP.md`. One entry per user-facing feature, with how to
   reach it, a check command with its expected result, and the code paths. Keep it to what exists; mark
   anything you could not run with `unverified:` and the reason.
4. **Write the skill** from `templates/verify-SKILL.md`, filling in the real commands. Keep it short: the
   map holds the detail.
5. **Prove the skill works**: in a fresh subagent (no context from this session), ask it to verify one feature
   from the map using only the skill. Fix whatever it trips on, then report what it ran.
6. Report: files written, the features mapped, anything `unverified:` and why. Don't commit; suggest the user
   commit `.claude/skills/verify/` so the whole team and cloud agents get it.

## `/verify-setup refresh`: maintain

Run when features changed, or when an agent got lost using the map.

1. Read the existing `FEATURE_MAP.md` and `SKILL.md`.
2. Diff the code's entry points against the map: `git log --since=<map's "updated" date> --name-only` plus
   a fresh scan of routes/commands/screens. List added, removed and moved features.
3. Rerun every check command in the map. A check that fails is either a bug (report it, don't "fix" the map
   to match) or a stale entry (update it).
4. Update the map and its `updated:` date. Report what changed and which checks failed.

## Rules

- A verification step must observe real behavior (HTTP response, process output, DB row, screenshot,
  trace). "It compiles" or "the unit tests pass" is not verification.
- Prefer commands with a clear pass/fail (`curl -fsS ... | jq -e '.status == "ok"'`) over output a human reads.
- Never point verification at production or shared environments. Local, a container, or a dev/test
  stack the user named.
- No secrets in the skill or map. Reference where they come from (`aws sso login`, `.env.example`).
