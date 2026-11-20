---
name: commit
description: Create git commits for the current changes with clear messages, one commit per concern. Use when the user says /commit or asks to commit their work.
disable-model-invocation: true
---

Each commit should describe one change on its own: git history is context for the next person or agent,
and a focused commit is easy to review and revert.

1. Run `git status` and `git diff` (staged and unstaged) to see what changed; check `git log -5 --oneline` for the message style.
2. Group the changes by concern (a bug fix, a refactor, a docs fix, a dependency bump are separate concerns).
   If there is more than one group, make one commit per group, in an order where each commit builds and makes
   sense alone. If one file mixes concerns, commit it with the main concern and say so in the report.
3. For each group, stage only its files by path (never `git add -A` or `git add .`; the ban-patterns hook
   blocks them). Do not stage secrets or local-only files.
4. Write a concise imperative subject (<= 72 chars) explaining the why; add a short body only if needed.
5. Commit. If a hook blocks (gitleaks, pre-commit), fix the finding rather than bypassing it (`--no-verify` is blocked).
6. Do not push unless the user asked. Report each commit's hash and subject.
