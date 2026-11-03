#!/usr/bin/env bash
# PreToolUse(Bash): before `git commit`, scan staged changes with gitleaks. Exit 2 blocks on findings.
# Note: only sees what is already staged (not files added in the same command via `git add && git commit`).
cmd="$(jq -r '.tool_input.command // empty' 2>/dev/null)"
grep -Eq '(^|[;&| ])git +commit( |$)' <<<"$cmd" || exit 0
command -v gitleaks >/dev/null || exit 0
out="$(gitleaks git --staged --no-banner --redact 2>&1)" && exit 0
echo "gitleaks found possible secrets in staged changes; fix before committing:" >&2
echo "$out" >&2
exit 2
