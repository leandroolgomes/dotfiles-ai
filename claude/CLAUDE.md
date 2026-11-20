# Global instructions

Rules tagged *(hook)* are enforced by a hook in `~/.claude/hooks`; the rest need judgment. A soft rule
that keeps getting broken should become a hard one: run `/learn`.

## Style
- Be concise. Lead with the answer or the result; skip preamble and recap.
- Reply in English. Code, commit messages and identifiers are always English.

## Safety
- Ask before anything irreversible or outward-facing: `git push`, force-push, deleting
  files/branches/repos, `gh repo create/delete`, publishing, sending messages.
- Before overwriting or deleting, look at the target first (e.g. check whether a repo/file
  already exists and what is in it).
- Never commit secrets. *(hook: gitleaks-commit scans staged changes on `git commit`)*
- Stage the files you changed by path. *(hook: ban-patterns blocks `git add -A`/`.` and `--no-verify`)*

## Environment
- macOS, zsh. `ls` is aliased to `eza`; use `command ls` when flags matter.
- Tool versions via `mise`; Python via `uv`. Prefer `fd`/`rg`/`bat` over `find`/`grep`/`cat` in shells.
- Dotfiles live in a public repo (dotfiles-ai); config files under `$HOME` may be symlinks into it.

## Stack
- Go, Node/TypeScript, Java. Use each ecosystem's standard formatter and test runner.

## Working style
Inspired by Karpathy's notes on LLM coding mistakes (via forrestchang/andrej-karpathy-skills).
Biased toward caution; for trivial tasks use judgment.

**Think before coding**
- State assumptions. If a request has several readings, present them instead of picking silently.
- If something is unclear, stop and ask. If a simpler approach exists, say so and push back.

**Simplicity first**
- Minimum code that solves the problem: no extra features, no single-use abstractions,
  no unrequested configurability, no error handling for impossible cases.

**Surgical changes**
- Prefer small, focused diffs. Every changed line must trace to the request.
- Match existing style *(formatting: format-on-edit runs the repo's formatter/linter)*. Do not refactor or "improve" adjacent code; mention unrelated dead code instead.
- Remove only the imports/functions that your own change made unused.
- Comments explain the code as it is: never its history or this conversation ("as requested", "changed to").
  Don't silence linters or skip tests to get green. *(hook: ban-patterns)*
- One concern per commit; history is context for the next reader. `/commit` splits mixed changes.

**Goal-driven execution**
- Turn tasks into verifiable goals: bug fix = failing test first, then make it pass; refactor = tests green before and after.
- For multi-step work, state a short plan with a check per step, then loop until the checks pass.
- Run the relevant tests/linters after changes and report real output; say so if something was not run.
  *(hook: require-checks blocks stopping once if code changed and no check ran after it)*
- Prove behavior, not just compilation: if the project has a `verify` skill, use it; if it has none and you
  keep guessing, suggest `/verify-setup`.
