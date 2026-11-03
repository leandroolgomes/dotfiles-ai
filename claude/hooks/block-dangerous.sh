#!/usr/bin/env bash
# PreToolUse(Bash): block clearly destructive commands (exit 2 = block, stderr goes to Claude).
# Guardrail against accidents, not a security boundary: plain pattern matching can be bypassed.
cmd="$(jq -r '.tool_input.command // empty' 2>/dev/null)"
[[ -z "$cmd" ]] && exit 0

block() { echo "Blocked by block-dangerous.sh: $1. Ask the user to run it themselves if intended." >&2; exit 2; }

grep -Eq 'rm +(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive.*--force)[^|;&]* +(/|~|\$HOME|/\*|~/\*)( |$)' <<<"$cmd" && block "rm -rf on / or home"
grep -Eq 'git +push[^|;&]*( -f( |$)|--force( |$))' <<<"$cmd" && block "git push --force (use --force-with-lease)"
grep -Eqi '(drop +(table|database|schema)|truncate +table)' <<<"$cmd" && block "destructive SQL"
grep -Eq 'terraform +(destroy|apply +.*-auto-approve)' <<<"$cmd" && block "terraform destroy/auto-approve"
grep -Eq 'gh +repo +delete' <<<"$cmd" && block "gh repo delete"
grep -Eq '(curl|wget)[^|;&]*\|[^|;&]*(sh|bash|zsh)( |$)' <<<"$cmd" && block "piping a download into a shell"
grep -Eq 'chmod +-R +777' <<<"$cmd" && block "chmod -R 777"
exit 0
