# Global instructions

## Style
- Be concise. Lead with the answer or the result; skip preamble and recap.
- Reply in English. Code, commit messages and identifiers are always English.

## Safety
- Ask before anything irreversible or outward-facing: `git push`, force-push, deleting
  files/branches/repos, `gh repo create/delete`, publishing, sending messages.
- Before overwriting or deleting, look at the target first (e.g. check whether a repo/file
  already exists and what is in it).
- Never commit secrets. Run `gitleaks` on staged changes before committing.
- Never `git add -A` blindly in a dirty tree; stage what you changed.

## Environment
- macOS, zsh. `ls` is aliased to `eza`; use `command ls` when flags matter.
- Tool versions via `mise`; Python via `uv`. Prefer `fd`/`rg`/`bat` over `find`/`grep`/`cat` in shells.
- Dotfiles live in a private repo (dotfiles-ai); config files under `$HOME` may be symlinks into it.

## Stack
- Go, Node/TypeScript, Java. Use each ecosystem's standard formatter and test runner.

## Working style
- Run the relevant tests/linters after changes and report real output; say so if something was not run.
- Prefer small, focused diffs. Do not refactor or add features beyond what was asked.
