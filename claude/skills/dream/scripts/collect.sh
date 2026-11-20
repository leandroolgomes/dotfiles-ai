#!/usr/bin/env bash
# collect.sh: the session transcripts /dream reads: top-level transcripts of every project changed in the
# last N days, newest first. Skips subagent transcripts and temp/scratchpad projects.
#
# Usage: collect.sh [--days N] [--max N] [--root DIR]
#   --days N    changed in the last N days (default 7)
#   --max N     at most N transcripts (default 40)
#   --root DIR  projects folder (default ~/.claude/projects)
# Output: one line per transcript: <project-dir-name><TAB><absolute path>. Nothing found = no output, exit 0.
set -euo pipefail

DAYS=7 MAX=40 ROOT="$HOME/.claude/projects"
while (($#)); do
  case "$1" in
    --days) DAYS="$2"; shift 2;;
    --max)  MAX="$2"; shift 2;;
    --root) ROOT="$2"; shift 2;;
    *)      echo "collect.sh: unknown option: $1" >&2; exit 2;;
  esac
done
[[ "$DAYS" =~ ^[0-9]+$ && "$MAX" =~ ^[0-9]+$ ]] || { echo "collect.sh: --days and --max take a number" >&2; exit 2; }
[[ -d "$ROOT" ]] || { echo "collect.sh: no such folder: $ROOT" >&2; exit 2; }
ROOT="$(cd "$ROOT" && pwd -P)"

files=()
while IFS= read -r -d '' f; do
  case "$(basename "$(dirname "$f")")" in -private-tmp-*|-private-var-*) continue;; esac
  files+=("$f")
done < <(find "$ROOT" -mindepth 2 -maxdepth 2 -name '*.jsonl' -mtime -"$DAYS" -print0)
((${#files[@]})) || exit 0

# ls -t sorts by modification time, newest first.
ls -t "${files[@]}" | head -n "$MAX" | while IFS= read -r f; do
  printf '%s\t%s\n' "$(basename "$(dirname "$f")")" "$f"
done
