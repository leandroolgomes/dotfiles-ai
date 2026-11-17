#!/usr/bin/env bash
# Stop hook: if the repo has an active BET.md (from /bet), don't let Claude finish until every proof item
# is checked with evidence under it (or marked [!] blocked with a reason) and the report lists decisions.
# Nudges once per stop: if Claude stops again right after being blocked (stop_hook_active), it is allowed,
# so asking the user a question mid-task still works. Unproven items stay visible in BET.md.
set -uo pipefail

input=$(cat)
command -v jq >/dev/null || exit 0
[[ "$(jq -r '.stop_hook_active // false' <<<"$input")" == "true" ]] && exit 0

cwd=$(jq -r '.cwd // empty' <<<"$input"); cwd=${cwd:-$PWD}
root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo "$cwd")
bet="$root/BET.md"
[[ -f "$bet" ]] || exit 0
grep -qE '^status:[[:space:]]*active' "$bet" || exit 0

missing=$(awk '
  /^## /           { in_proof = ($0 ~ /^## Done means/); next }
  /^### Decisions/ { in_dec = 1; next }
  /^##/            { in_dec = 0 }
  in_dec && NF && $0 !~ /^</ { decisions++ }
  in_proof && /^- \[ \]/ { flush(); print "unchecked: " substr($0, 7); next }
  in_proof && /^- \[[xX]\]/ { flush(); pending = substr($0, 7); next }
  in_proof && /^- \[!\]/ { flush(); next }
  in_proof && /^[[:space:]]+[^[:space:]]/ { pending = ""; next }
  function flush() { if (pending != "") print "no evidence under: " pending; pending = "" }
  END { flush(); if (!decisions) print "report: \"### Decisions you didn'\''t make\" is empty (write \"none\" if there were none)" }
' "$bet")

[[ -z "$missing" ]] && exit 0

reason="BET.md ($bet) is active and the finish line is not met:
$missing

Before stopping: run the proof, check each item and put the evidence (command + key output) on indented
lines under it. If an item can't be proven here, mark it - [!] with the reason. Fill the Report section
(Bet vs. what I did, Decisions you didn't make). If you are only stopping to ask the user something, stop again."
jq -n --arg r "$reason" '{decision: "block", reason: $r}'
