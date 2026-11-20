#!/usr/bin/env bash
# PreToolUse(Bash|Edit|Write|MultiEdit): block patterns agents use to cheat checks or leave noise
# (lint suppressions, skipped tests, comments that narrate history, blind `git add -A`, `--no-verify`).
# Rules: ban-patterns.rules next to this script, plus ~/work-context/rules.d/*.rules (private, per company).
# Code rules only block NEW matches: editing around an existing `//nolint` is fine, adding one is not.
# Exit 2 = block (stderr goes to Claude). Fail closed if jq can't parse the input.
set -uo pipefail

input=$(cat)
tool=$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null) || { echo "ban-patterns.sh: jq failed; cannot inspect the tool call. Install jq." >&2; exit 2; }

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rule_files=("$HOOK_DIR/ban-patterns.rules")
for f in "${WORK_CONTEXT:-$HOME/work-context}"/rules.d/*.rules; do [[ -f "$f" ]] && rule_files+=("$f"); done

# count <regex> <text>: number of matching lines (case-insensitive)
count() { [[ -z "$2" ]] && { echo 0; return; }; grep -Eic -- "$1" <<<"$2" || true; }

is_code_file() {
  local path="$1" first_line="$2"
  [[ "$path" == *ban-patterns* ]] && return 1   # the rules and their tests quote the patterns on purpose
  case "${path##*/}" in
    *.md|*.markdown|*.txt|*.rst|*.rules|*.json|*.yaml|*.yml|*.toml|*.lock|*.csv) return 1;;
    *.go|*.js|*.jsx|*.mjs|*.cjs|*.ts|*.tsx|*.py|*.java|*.kt|*.kts|*.sh|*.bash|*.zsh|*.lua|*.rb|*.rs|*.c|*.h|*.cc|*.cpp|*.cs|*.swift|*.scala|*.php|*.vue|*.svelte) return 0;;
    *.*) return 1;;
  esac
  [[ "$first_line" == '#!'* ]]   # extensionless: code if it is a script
}

violations=()
check_rules() {   # check_rules <scope> <new text> <old text>
  local scope rx msg
  for rf in "${rule_files[@]}"; do
    while IFS=$'\t' read -r scope rx msg; do
      [[ -z "$scope" || "$scope" == \#* || "$scope" != "$1" || -z "$rx" ]] && continue
      if (( $(count "$rx" "$2") > $(count "$rx" "$3") )); then violations+=("$msg  [rule: $rx]"); fi
    done <"$rf"
  done
}

case "$tool" in
  Bash)
    check_rules bash "$(jq -r '.tool_input.command // empty' <<<"$input")" ""
    ;;
  Edit|Write|MultiEdit)
    path=$(jq -r '.tool_input.file_path // empty' <<<"$input")
    case "$tool" in
      Edit)      new=$(jq -r '.tool_input.new_string // empty' <<<"$input")
                 old=$(jq -r '.tool_input.old_string // empty' <<<"$input");;
      MultiEdit) new=$(jq -r '[.tool_input.edits[]?.new_string] | join("\n")' <<<"$input")
                 old=$(jq -r '[.tool_input.edits[]?.old_string] | join("\n")' <<<"$input");;
      Write)     new=$(jq -r '.tool_input.content // empty' <<<"$input")
                 old=""; [[ -f "$path" ]] && old=$(cat "$path");;
    esac
    first=$(head -n1 <<<"$new"); [[ -f "$path" ]] && first=$(head -n1 "$path")
    is_code_file "$path" "$first" && check_rules code "$new" "$old"
    ;;
  *) exit 0;;
esac

((${#violations[@]})) || exit 0
{
  echo "Blocked by ban-patterns.sh:"
  printf -- '- %s\n' "${violations[@]}"
  echo "If this is truly needed, explain why and ask the user to make that change themselves."
} >&2
exit 2
