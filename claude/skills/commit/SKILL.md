---
name: commit
description: Create a git commit for the current changes with a clear message. Use when the user says /commit or asks to commit their work.
disable-model-invocation: true
---

1. Run `git status` and `git diff` (staged and unstaged) to see what changed; check `git log -5 --oneline` for the message style.
2. Stage only the files that belong to this change (never blind `git add -A`). Do not stage secrets or local-only files.
3. Write a concise imperative subject (<= 72 chars) explaining the why; add a short body only if needed.
4. Commit. If the gitleaks hook blocks, fix the finding rather than bypassing it.
5. Do not push unless the user asked. Report the commit hash and subject.
