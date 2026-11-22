#!/usr/bin/env bash
# Tests for bin/agent-metrics, run against fixture transcripts.
# Usage: bin/tests/agent-metrics/run.sh   (exit 0 = all pass). Run by bin/dotfiles-check.
set -uo pipefail

BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/agent-metrics"
WORK=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$WORK"' EXIT
export WORK_CONTEXT="$WORK/work-context"
pass=0 fail=0

ok()  { pass=$((pass + 1)); }
bad() { fail=$((fail + 1)); printf '  FAIL %s\n' "$*"; }
# check NAME JQ_EXPR EXPECTED: run jq on the last JSON output and compare.
check() { local got; got=$(jq -r "$2" <<<"$out"); [[ "$got" == "$3" ]] && ok || bad "$1: expected '$3', got '$got'"; }

root="$WORK/projects"
mkdir -p "$root/-Users-x-dev-a/s1/subagents" "$root/-private-var-auto"

# One interactive session in 2026-W46 and one in 2026-W47 (2026-11-16..22).
cat >"$root/-Users-x-dev-a/s0.jsonl" <<'EOF'
{"type":"user","entrypoint":"cli","timestamp":"2026-11-10T09:00:00.000Z","message":{"role":"user","content":"please stop using git add -A"}}
EOF
cat >"$root/-Users-x-dev-a/s1.jsonl" <<'EOF'
{"type":"user","entrypoint":"cli","timestamp":"2026-11-17T09:00:00.000Z","message":{"role":"user","content":"add a retry to the client"}}
{"type":"assistant","entrypoint":"cli","timestamp":"2026-11-17T09:00:05.000Z","message":{"id":"m1","usage":{"input_tokens":10,"cache_creation_input_tokens":100,"cache_read_input_tokens":1000,"output_tokens":5}}}
{"type":"assistant","entrypoint":"cli","timestamp":"2026-11-17T09:00:06.000Z","message":{"id":"m1","usage":{"input_tokens":10,"cache_creation_input_tokens":100,"cache_read_input_tokens":1000,"output_tokens":5}}}
{"type":"user","entrypoint":"cli","timestamp":"2026-11-17T09:01:00.000Z","message":{"role":"user","content":[{"type":"tool_result","is_error":true,"content":"PreToolUse:Bash hook error: [$HOME/.claude/hooks/ban-patterns.sh]: Blocked by ban-patterns.sh:\n- Blind staging. Stage the specific files of this change  [rule: git add -A]\nIf this is truly needed, explain why."}]}}
{"type":"user","entrypoint":"cli","timestamp":"2026-11-17T09:02:00.000Z","message":{"role":"user","content":[{"type":"tool_result","is_error":true,"content":[{"type":"text","text":"PreToolUse:Bash hook error: [$HOME/.claude/hooks/block-dangerous.sh]: Blocked by block-dangerous.sh: piping a download into a shell."}]}]}}
{"type":"user","entrypoint":"cli","timestamp":"2026-11-17T09:03:00.000Z","message":{"role":"user","content":[{"type":"tool_result","is_error":true,"content":"The user doesn't want to proceed with this tool use. The tool use was rejected."}]}}
{"type":"user","entrypoint":"cli","timestamp":"2026-11-17T09:03:01.000Z","message":{"role":"user","content":[{"type":"text","text":"[Request interrupted by user for tool use]"}]}}
{"type":"user","entrypoint":"cli","timestamp":"2026-11-17T09:04:00.000Z","message":{"role":"user","content":[{"type":"text","text":"[Request interrupted by user]"}]}}
{"type":"user","entrypoint":"cli","isMeta":true,"timestamp":"2026-11-17T09:05:00.000Z","message":{"role":"user","content":"Stop hook feedback:\nCode changed after the last check (last edit: x.go) and no test, lint, build or verify ran since."}}
{"type":"user","entrypoint":"cli","timestamp":"2026-11-17T09:06:00.000Z","message":{"role":"user","content":"no, don't use git add -A here"}}
{"type":"user","entrypoint":"cli","timestamp":"2026-11-17T09:07:00.000Z","message":{"role":"user","content":[{"type":"tool_result","is_error":true,"content":"Exit code 1\nsome command failed"}]}}
EOF

# Subagent transcript: its tokens count, its interrupts do not, and it is not a session.
cat >"$root/-Users-x-dev-a/s1/subagents/agent-1.jsonl" <<'EOF'
{"type":"assistant","isSidechain":true,"entrypoint":"cli","timestamp":"2026-11-17T09:00:30.000Z","message":{"id":"sub1","usage":{"input_tokens":1,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":2}}}
{"type":"user","isSidechain":true,"entrypoint":"cli","timestamp":"2026-11-17T09:00:31.000Z","message":{"role":"user","content":[{"type":"text","text":"[Request interrupted by user]"}]}}
EOF

# Automated run (claude -p): reported separately.
cat >"$root/-private-var-auto/s2.jsonl" <<'EOF'
{"type":"user","entrypoint":"sdk-cli","timestamp":"2026-11-18T09:00:00.000Z","message":{"role":"user","content":"triage issue 42"}}
{"type":"assistant","entrypoint":"sdk-cli","timestamp":"2026-11-18T09:00:05.000Z","message":{"id":"a1","usage":{"input_tokens":3,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":7}}}
{"type":"user","entrypoint":"sdk-cli","timestamp":"2026-11-18T09:01:00.000Z","message":{"role":"user","content":[{"type":"text","text":"[Request interrupted by user]"}]}}
EOF

mkdir -p "$WORK_CONTEXT/metrics"
printf '# label\tregex\tsince\nblind-staging\tgit add -A\t2026-11-16\n' >"$WORK_CONTEXT/metrics/watch.tsv"

echo "agent-metrics: counting"
out=$("$BIN" --projects "$root" --state "$WORK/state.json" --no-save --json); rc=$?
[[ $rc == 0 ]] && ok || bad "--json exits $rc"
W='.weeks["2026-W47"].interactive'
check "sessions" "$W.sessions" 1
check "sessions in another week" '.weeks["2026-W46"].interactive.sessions' 1
check "interrupts skip sidechain and tool-use variant" "$W.interrupts" 1
check "rejections" "$W.rejections" 1
check "hook blocks by hook" "$W.hook_block[\"ban-patterns.sh\"]" 1
check "block-dangerous with array content" "$W.hook_block[\"block-dangerous.sh\"]" 1
check "plain tool errors are not blocks" "$W.hook_block | length" 2
check "ban-pattern rule" "$W.rule_block[\"Blind staging. Stage the specific files of this change\"]" 1
check "stop block named by hook" "$W.stop_block[\"require-checks.sh\"]" 1
check "output tokens dedupe by message id + subagent" "$W.tokens_out" 7
check "total tokens" "$W.tokens_total" 1118
check "automated sessions" '.weeks["2026-W47"].automated.sessions' 1
check "automated tokens" '.weeks["2026-W47"].automated.tokens_total' 10
check "watch counts user prompts by week (after)" "$W.watch[\"blind-staging\"]" 1
check "watch counts user prompts by week (before)" '.weeks["2026-W46"].interactive.watch["blind-staging"]' 1
check "watch before/after" '.watched[0] | "\(.label) \(.before.matches)/\(.before.sessions) \(.after.matches)/\(.after.sessions)"' "blind-staging 1/1 1/1"

echo "agent-metrics: history survives deleted logs"
"$BIN" --projects "$root" --state "$WORK/state.json" --json >/dev/null || bad "save run failed"
[[ -f "$WORK/state.json" ]] && ok || bad "state file not written"
rm "$root/-Users-x-dev-a/s1.jsonl"
out=$("$BIN" --projects "$root" --state "$WORK/state.json" --no-save --json)
check "sessions kept from state" "$W.sessions" 1
check "rule kept from state" "$W.rule_block | length" 1

echo "agent-metrics: text report"
txt=$("$BIN" --projects "$root" --state "$WORK/state.json" --no-save --weeks 2 2>&1); rc=$?
[[ $rc == 0 ]] && ok || bad "text report exits $rc: $txt"
grep -q '2026-W47' <<<"$txt" && ok || bad "text report lacks 2026-W47: $txt"
grep -q 'Blind staging' <<<"$txt" && ok || bad "text report lacks the rule: $txt"
grep -q 'blind-staging' <<<"$txt" && ok || bad "text report lacks the watch: $txt"

echo "agent-metrics: errors"
"$BIN" --projects "$WORK/missing" --no-save >/dev/null 2>&1; rc=$?
[[ $rc == 2 ]] && ok || bad "missing projects dir should exit 2, got $rc"

printf '%d passed, %d failed\n' "$pass" "$fail"
((fail == 0))
