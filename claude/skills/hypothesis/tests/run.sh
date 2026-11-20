#!/usr/bin/env bash
# Tests for the /hypothesis Stop hook (hooks/proof-gate.sh). Run by bin/dotfiles-check.
set -uo pipefail
GATE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/hooks/proof-gate.sh"
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
git -C "$WORK" init -q
pass=0 fail=0

# gate_case <want: block|pass> <label> <HYPOTHESIS.md content or ""> [stop_hook_active]
gate_case() {
  rm -f "$WORK/HYPOTHESIS.md"; [[ -n "$3" ]] && printf '%s\n' "$3" >"$WORK/HYPOTHESIS.md"
  local out; out=$(jq -n --arg c "$WORK" --argjson a "${4:-false}" '{cwd:$c, stop_hook_active:$a}' | "$GATE" 2>/dev/null)
  local got=pass; [[ "$(jq -r '.decision // empty' <<<"$out" 2>/dev/null)" == block ]] && got=block
  if [[ "$got" == "$1" ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "  FAIL proof-gate: $2 → $got, want $1"; fi
}

head='---
status: active
---
## Done means (proof)'
report='## Report
### Decisions you didn'"'"'t make
D1. used exponential backoff | linear | matches the API docs'

echo "hypothesis: proof-gate"
gate_case pass  "no HYPOTHESIS.md" ""
gate_case block "unchecked proof item" "$head
- [ ] p99 under 200ms
$report"
gate_case block "checked without evidence" "$head
- [x] p99 under 200ms
$report"
gate_case pass  "checked with evidence" "$head
- [x] p99 under 200ms
  \$ make bench → p99 180ms
$report"
gate_case pass  "blocked item with reason" "$head
- [!] load test needs staging credentials
$report"
gate_case block "empty decisions" "$head
- [x] tests pass
  \$ go test ./... → ok
## Report
### Decisions you didn't make"
gate_case pass  "closed hypothesis" "${head/active/closed}
- [ ] anything"
gate_case pass  "stop_hook_active lets it stop" "$head
- [ ] p99 under 200ms
$report" true

echo "hypothesis: $pass passed, $fail failed"
((fail == 0))
