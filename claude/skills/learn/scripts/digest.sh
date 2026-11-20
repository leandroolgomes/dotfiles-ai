#!/usr/bin/env bash
# digest.sh: compact, chronological view of a Claude Code session transcript (JSONL), so a failure can be
# read without loading the whole file: user messages, assistant text, tool calls, failed tool results.
# Also reads `claude -p --output-format stream-json` output (same event shape).
#
# Usage: digest.sh [TRANSCRIPT.jsonl | SESSION_ID | --list [N]] [--width N]
#   no argument   the most recent session for the current directory
#   --list [N]    list the N most recent sessions for the current directory (default 10)
set -euo pipefail

WIDTH=300 ARG="" LIST=0 N=10
while (($#)); do
  case "$1" in
    --width) WIDTH="$2"; shift 2;;
    --list)  LIST=1; [[ "${2:-}" =~ ^[0-9]+$ ]] && { N="$2"; shift; }; shift;;
    *)       ARG="$1"; shift;;
  esac
done

project_dir="$HOME/.claude/projects/$(pwd -P | sed 's#[^A-Za-z0-9]#-#g')"
if ((LIST)); then
  [[ -d "$project_dir" ]] || { echo "no sessions for $(pwd -P)" >&2; exit 1; }
  find "$project_dir" -maxdepth 1 -name '*.jsonl' -print0 | xargs -0 ls -t | head -n "$N" | while IFS= read -r f; do
    first=$(jq -r 'select(.type=="user") | .message.content | if type=="string" then . else (map(select(.type=="text").text) | join(" ")) end' "$f" 2>/dev/null \
      | sed 's/^[[:space:]]*//' | grep -v -e '^<' -e '^$' | head -n1 | cut -c1-80 || true)
    printf '%s  %s  %s\n' "$(date -r "$f" '+%Y-%m-%d %H:%M')" "$(basename "$f" .jsonl)" "$first"
  done
  exit 0
fi

if [[ -z "$ARG" ]]; then
  file=$(find "$project_dir" -maxdepth 1 -name '*.jsonl' -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -n1)
elif [[ -f "$ARG" ]]; then file="$ARG"
else file=$(find "$HOME/.claude/projects" -name "$ARG.jsonl" -print -quit)
fi
[[ -n "${file:-}" && -f "$file" ]] || { echo "transcript not found: ${ARG:-latest for $(pwd -P)}" >&2; exit 1; }

echo "# $file"
jq -r --argjson w "$WIDTH" '
  def short: tostring | gsub("\\s+"; " ") | if length > $w then .[0:$w] + "…" else . end;
  def input_of: if .name == "Bash" then .input.command
    elif (.input.file_path // .input.notebook_path) then (.input.file_path // .input.notebook_path)
    elif .input.skill then .input.skill + " " + (.input.args // "")
    elif .input.subagent_type then .input.subagent_type + ": " + (.input.description // .input.prompt // "")
    else (.input | tojson) end;
  if .type == "user" then
    (.message.content | if type == "string" then
        (if startswith("<") then empty else "USER    " + short end)
      else .[] |
        if .type == "text" then
          (if (.text | startswith("<")) then empty
           elif (.text | startswith("Base directory for this skill")) then "  SKILL loaded: " + (.text | split("\n")[0] | sub("Base directory for this skill: "; "") | short)
           else "USER    " + (.text | short) end)
        elif .type == "tool_result" and .is_error == true then
          "  ERROR " + ((.content | if type == "array" then map(.text? // "") | join(" ") else . end) | short)
        else empty end
      end)
  elif .type == "assistant" then
    (.message.content[]? |
      if .type == "text" then "AGENT   " + (.text | short)
      elif .type == "tool_use" then "  TOOL  " + .name + ": " + (input_of | short)
      else empty end)
  elif .type == "result" then "RESULT  " + ((.result // .subtype // "") | short)
  else empty end
' "$file"
