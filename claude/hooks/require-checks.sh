#!/usr/bin/env bash
# Stop hook: "CI is red, you can't merge", done locally. If code was edited this session and no
# test/lint/build/verify ran after the last edit, block the stop once and ask for the checks.
# Nudges once per unverified edit (state in $TMPDIR), and never twice in a row (stop_hook_active),
# so it can't loop. Counts as a check: a Bash command matching CHECK_RX (or a line of
# ~/work-context/rules.d/check-commands.txt), the `verify` skill, or the test-runner agent.
# Disable for a session with CLAUDE_REQUIRE_CHECKS=0.
set -uo pipefail

[[ "${CLAUDE_REQUIRE_CHECKS:-1}" == 0 ]] && exit 0
command -v jq >/dev/null || exit 0
input=$(cat)
[[ "$(jq -r '.stop_hook_active // false' <<<"$input")" == "true" ]] && exit 0
transcript=$(jq -r '.transcript_path // empty' <<<"$input")
session=$(jq -r '.session_id // "unknown"' <<<"$input")
[[ -f "$transcript" ]] || exit 0

CHECK_RX='(^|[;&|(])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^ ]* +)*(time +)?([^ ;&|]*/)?((go|cargo) +(test|vet|build)|golangci-lint|staticcheck|(npm|pnpm|yarn|bun)( +run)? +(test|lint|build|check|typecheck|verify)|npx +(tsc|eslint|vitest|jest|playwright)|tsc|eslint|vitest|jest|pytest|uv +run +(pytest|ruff|mypy)|ruff|mypy|(\./)?gradlew|gradle|mvn|make|just|mise +run|task +|shellcheck|dotfiles-check|bats|[^ ]*tests?/run\.sh|skill-eval)( |$)'
extra="${WORK_CONTEXT:-$HOME/work-context}/rules.d/check-commands.txt"
if [[ -f "$extra" ]]; then
  while IFS= read -r l; do [[ -n "$l" && "$l" != \#* ]] && CHECK_RX="$CHECK_RX|$l"; done <"$extra"
fi

# One line per tool call, in order: name<TAB>file_path|command|skill|subagent_type
calls=$(jq -rc 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")
  | [.name, (.input.file_path // .input.notebook_path // .input.command // .input.skill // .input.subagent_type // "" | tostring | gsub("[\t\n]"; " "))] | @tsv' \
  "$transcript" 2>/dev/null) || exit 0

tmp="${TMPDIR:-/tmp}"; tmp="${tmp%/}"
IFS=$'\t' read -r last_edit last_file last_check < <(CHECK_RX="$CHECK_RX" TMPD="$tmp" awk -F'\t' '
  BEGIN { rx = ENVIRON["CHECK_RX"]; tmp = ENVIRON["TMPD"] }
  function is_code(p) {
    if (p == "" || index(p, tmp) == 1 || p ~ /^\/(private\/)?tmp\//) return 0
    if (p ~ /\/\.claude\/(projects|plans|todos)\//) return 0
    return p !~ /\.(md|markdown|txt|rst|csv|log)$/
  }
  $1 ~ /^(Edit|Write|MultiEdit|NotebookEdit)$/ && is_code($2) { last_edit = NR; last_file = $2 }
  $1 == "Bash" && $2 ~ rx { last_check = NR }
  $1 == "Skill" && $2 ~ /(^|:)verify$/ { last_check = NR }
  ($1 == "Agent" || $1 == "Task") && $2 == "test-runner" { last_check = NR }
  END { printf "%d\t%s\t%d\n", last_edit, (last_file == "" ? "-" : last_file), last_check }
' <<<"$calls")

(( last_edit > 0 && last_edit > last_check )) || exit 0

state="$tmp/claude-require-checks-$session"
[[ "$(cat "$state" 2>/dev/null)" == "$last_edit" ]] && exit 0   # already nudged for this edit
echo "$last_edit" >"$state"

reason="Code changed after the last check (last edit: $last_file) and no test, lint, build or verify ran since.
Run the project's checks for this change and report the real output. If this project has no checks that
cover the change, say so plainly in your reply and stop again."
jq -n --arg r "$reason" '{decision: "block", reason: $r}'
