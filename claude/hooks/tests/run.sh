#!/usr/bin/env bash
# Tests for claude/hooks. Table-driven cases live in <hook>.cases; the stateful hooks
# (require-checks, format-on-edit) are tested below with temp transcripts and files.
# Usage: claude/hooks/tests/run.sh   (exit 0 = all pass). Run by bin/dotfiles-check.
set -uo pipefail

HOOKS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS="$HOOKS/tests"
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
export WORK_CONTEXT="$WORK/no-work-context" TMPDIR="$WORK/tmp"; mkdir -p "$TMPDIR"
pass=0 fail=0

ok()  { pass=$((pass + 1)); }
bad() { fail=$((fail + 1)); printf '  FAIL %s\n' "$*"; }

# tool_json <tool> <args...>: the PreToolUse/PostToolUse input Claude Code sends
tool_json() {
  local tool="$1"; shift
  case "$tool" in
    Bash)  jq -n --arg c "$1" '{tool_name:"Bash", tool_input:{command:$c}}';;
    Edit)  jq -n --arg f "$1" --arg o "$2" --arg n "$3" '{tool_name:"Edit", tool_input:{file_path:$f, old_string:$o, new_string:$n}}';;
    Write) jq -n --arg f "$1" --arg c "$2" '{tool_name:"Write", tool_input:{file_path:$f, content:$c}}';;
    *)     jq -n --arg t "$tool" --arg f "${1:-}" '{tool_name:$t, tool_input:{file_path:$f}}';;
  esac
}

run_cases() {   # run_cases <hook>
  local hook="$1" exp tool a b c got
  while IFS=$'\t' read -r exp tool a b c; do
    [[ -z "$exp" || "$exp" == \#* ]] && continue
    a=$(printf '%b' "$a"); b=$(printf '%b' "$b"); c=$(printf '%b' "$c")
    (cd "$WORK" && tool_json "$tool" "$a" "$b" "$c" | "$HOOKS/$hook.sh" >/dev/null 2>&1); got=$?
    [[ "$got" == "$exp" ]] && ok || bad "$hook: $tool ${a//$'\n'/⏎} ${b:+| ${b//$'\n'/⏎}} ${c:+| ${c//$'\n'/⏎}} → exit $got, want $exp"
  done <"$TESTS/$hook.cases"
}

echo "hooks: table cases"
run_cases block-dangerous
run_cases ban-patterns

echo "hooks: ban-patterns private overlay"
mkdir -p "$WORK_CONTEXT/rules.d"
printf 'code\tuseEffect\\(\tuseEffect is banned in this org\n' >"$WORK_CONTEXT/rules.d/acme.rules"
(cd "$WORK" && tool_json Edit a.tsx 'x' 'useEffect(() => {})' | "$HOOKS/ban-patterns.sh" >/dev/null 2>&1); got=$?
[[ $got == 2 ]] && ok || bad "overlay rule did not block (exit $got)"
rm -rf "$WORK_CONTEXT"

# --- require-checks: build transcripts as Claude Code writes them (JSONL, one tool_use per line here)
echo "hooks: require-checks"
tx() {   # tx <file> <name> <input-json>...  (pairs)
  local f="$1"; shift; : >"$f"
  while (($#)); do
    jq -nc --arg n "$1" --argjson i "$2" '{type:"assistant", message:{content:[{type:"tool_use", name:$n, input:$i}]}}' >>"$f"
    shift 2
  done
}
stop_in() { jq -n --arg t "$1" --arg s "$2" --argjson a "${3:-false}" '{transcript_path:$t, session_id:$s, stop_hook_active:$a}'; }
rc_case() {   # rc_case <want: block|pass> <label> <session> [active]
  local out; out=$(stop_in "$WORK/t.jsonl" "$3" "${4:-false}" | "$HOOKS/require-checks.sh" 2>/dev/null)
  if [[ "$1" == block ]]; then [[ "$(jq -r '.decision // empty' <<<"$out" 2>/dev/null)" == block ]] && ok || bad "require-checks: $2 should block"
  else [[ -z "$out" ]] && ok || bad "require-checks: $2 should pass (got: $out)"; fi
}

tx "$WORK/t.jsonl" Edit '{"file_path":"/repo/main.go"}'
rc_case block "edit without check" s1
rc_case pass  "second stop for the same edit (nudged once)" s1
rc_case pass  "stop_hook_active" s2 true
tx "$WORK/t.jsonl" Edit '{"file_path":"/repo/main.go"}' Bash '{"command":"go test ./..."}'
rc_case pass "edit then go test" s3
tx "$WORK/t.jsonl" Bash '{"command":"go test ./..."}' Edit '{"file_path":"/repo/main.go"}'
rc_case block "check then edit" s4
tx "$WORK/t.jsonl" Edit '{"file_path":"/repo/README.md"}'
rc_case pass "docs-only edit" s5
tx "$WORK/t.jsonl" Edit '{"file_path":"/repo/a.ts"}' Bash '{"command":"cd web && pnpm run lint"}'
rc_case pass "pnpm run lint" s6
tx "$WORK/t.jsonl" Edit '{"file_path":"/repo/a.ts"}' Skill '{"skill":"verify"}'
rc_case pass "verify skill" s7
tx "$WORK/t.jsonl" Edit '{"file_path":"/repo/a.ts"}' Agent '{"subagent_type":"test-runner","prompt":"x"}'
rc_case pass "test-runner agent" s8
tx "$WORK/t.jsonl" Edit '{"file_path":"/repo/a.go"}' Bash '{"command":"echo go test"}'
rc_case block "echo is not a check" s9
tx "$WORK/t.jsonl" Edit "{\"file_path\":\"$TMPDIR/scratch.py\"}"
rc_case pass "scratch file under TMPDIR" s10
tx "$WORK/t.jsonl" Edit '{"file_path":"/repo/a.go"}' Bash '{"command":"just verify"}'
rc_case pass "just verify" s11
tx "$WORK/t.jsonl" Edit '{"file_path":"/repo/a.sh"}' Bash '{"command":"cd /repo && bin/dotfiles-check 2>&1 | grep ok"}'
rc_case pass "check run by path (bin/dotfiles-check)" s13
tx "$WORK/t.jsonl" Edit '{"file_path":"/repo/a.go"}' Bash '{"command":"cat bin/go-test-notes"}'
rc_case block "a path that merely contains a check name" s14
mkdir -p "$WORK_CONTEXT/rules.d"; echo 'acme-ci( |$)' >"$WORK_CONTEXT/rules.d/check-commands.txt"
tx "$WORK/t.jsonl" Edit '{"file_path":"/repo/a.go"}' Bash '{"command":"acme-ci --fast"}'
rc_case pass "company check command from rules.d" s12
rm -rf "$WORK_CONTEXT"

# --- format-on-edit: only the tools present on this machine are exercised
echo "hooks: format-on-edit"
fe() { jq -n --arg f "$1" '{tool_name:"Edit", tool_input:{file_path:$f}}' | "$HOOKS/format-on-edit.sh" >/dev/null 2>&1; }
if command -v gofmt >/dev/null; then
  printf 'package x\nfunc  A( ) int {return 1}\n' >"$WORK/a.go"
  fe "$WORK/a.go"; got=$?
  [[ $got == 0 ]] && grep -q 'func A() int' "$WORK/a.go" && ok || bad "format-on-edit: gofmt did not format (exit $got)"
  printf 'package x\nfunc A( {\n' >"$WORK/b.go"
  fe "$WORK/b.go"; [[ $? == 2 ]] && ok || bad "format-on-edit: Go syntax error not reported"
fi
if command -v shellcheck >/dev/null; then
  printf '#!/usr/bin/env bash\ncd $1\n' >"$WORK/tool"
  fe "$WORK/tool"; [[ $? == 2 ]] && ok || bad "format-on-edit: shellcheck warning not reported"
  printf '#!/usr/bin/env bash\ncd "$1" || exit\n' >"$WORK/tool2"
  fe "$WORK/tool2"; [[ $? == 0 ]] && ok || bad "format-on-edit: clean script reported"
fi
printf 'hello\n' >"$WORK/notes.md"
fe "$WORK/notes.md"; [[ $? == 0 ]] && ok || bad "format-on-edit: markdown should be ignored"
CLAUDE_FORMAT_ON_EDIT=0 fe "$WORK/b.go"; [[ $? == 0 ]] && ok || bad "format-on-edit: CLAUDE_FORMAT_ON_EDIT=0 not honored"

echo "hooks: $pass passed, $fail failed"
((fail == 0))
