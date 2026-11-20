#!/usr/bin/env bash
# collect.sh: the session transcripts /dream reads: top-level transcripts of every project changed in the
# last N days, newest first. Skips subagent transcripts and temp/scratchpad projects.
#
# Usage: collect.sh [--days N] [--max N] [--per-project N] [--root DIR]
#   --days N         changed in the last N days (default 7)
#   --max N          at most N transcripts (default 40)
#   --per-project N  at most N per project, so one busy project can't push out the others (default 10)
#   --root DIR       projects folder (default ~/.claude/projects)
# Output: one line per transcript: <project-dir-name><TAB><absolute path>. Nothing found = no output, exit 0.
# When a cap drops transcripts, one line on stderr says how many were kept.
set -euo pipefail

DAYS=7 MAX=40 PER=10 ROOT="$HOME/.claude/projects"
while (($#)); do
  case "$1" in
    --days)        DAYS="$2"; shift 2;;
    --max)         MAX="$2"; shift 2;;
    --per-project) PER="$2"; shift 2;;
    --root)        ROOT="$2"; shift 2;;
    *)             echo "collect.sh: unknown option: $1" >&2; exit 2;;
  esac
done
[[ "$DAYS" =~ ^[0-9]+$ && "$MAX" =~ ^[0-9]+$ && "$PER" =~ ^[0-9]+$ ]] \
  || { echo "collect.sh: --days, --max and --per-project take a number" >&2; exit 2; }
[[ -d "$ROOT" ]] || { echo "collect.sh: no such folder: $ROOT" >&2; exit 2; }
ROOT="$(cd "$ROOT" && pwd -P)"

files=()
while IFS= read -r -d '' f; do
  case "$(basename "$(dirname "$f")")" in -private-tmp-*|-private-var-*) continue;; esac
  files+=("$f")
done < <(find "$ROOT" -mindepth 2 -maxdepth 2 -name '*.jsonl' -mtime -"$DAYS" -print0)
((${#files[@]})) || exit 0

# ls -t sorts by modification time, newest first. awk reads the whole listing (no early close, so no SIGPIPE)
# and keeps the newest PER per project, then the newest MAX overall.
ls -t "${files[@]}" | awk -v max="$MAX" -v per="$PER" '
  { n = split($0, part, "/"); proj = part[n - 1]; total++ }
  seen[proj] < per && kept < max { seen[proj]++; kept++; print proj "\t" $0 }
  END { if (kept < total) printf "collect.sh: kept %d of %d transcripts (--max %d, --per-project %d)\n", kept, total, max, per > "/dev/stderr" }'
