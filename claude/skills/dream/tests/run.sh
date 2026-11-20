#!/usr/bin/env bash
# Tests for the dream skill's scripts (collect.sh, target-ok.sh), run with temp fixtures.
# Usage: claude/skills/dream/tests/run.sh   (exit 0 = all pass). Run by bin/dotfiles-check.
set -uo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
WORK=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$WORK"' EXIT
pass=0 fail=0

ok()  { pass=$((pass + 1)); }
bad() { fail=$((fail + 1)); printf '  FAIL %s\n' "$*"; }

echo "dream: collect.sh"
root="$WORK/projects"
mkdir -p "$root/-Users-x-dev-a/s1/subagents" "$root/-Users-x-dev-b" "$root/-private-tmp-x" "$root/-private-var-y"
for f in -Users-x-dev-a/s1.jsonl -Users-x-dev-b/s2.jsonl -Users-x-dev-a/s1/subagents/sub.jsonl \
         -private-tmp-x/s3.jsonl -private-var-y/s4.jsonl -Users-x-dev-a/old.jsonl; do
  echo '{}' >"$root/$f"
done
touch -t "$(date -v-30d '+%Y%m%d%H%M')" "$root/-Users-x-dev-a/old.jsonl"

out=$("$SCRIPTS/collect.sh" --root "$root"); rc=$?
[[ $rc == 0 ]] && ok || bad "default run exits $rc"
[[ $(grep -c . <<<"$out") == 2 ]] && ok || bad "default run should list 2 transcripts, got: $out"
grep -qxF -e $'-Users-x-dev-a\t'"$root/-Users-x-dev-a/s1.jsonl" <<<"$out" && ok || bad "missing s1 as project<TAB>path: $out"
grep -qxF -e $'-Users-x-dev-b\t'"$root/-Users-x-dev-b/s2.jsonl" <<<"$out" && ok || bad "missing s2 as project<TAB>path: $out"
grep -q -e /subagents/ -e '^-private' -e old.jsonl <<<"$out" && bad "lists an excluded transcript: $out" || ok

out=$("$SCRIPTS/collect.sh" --root "$root" --days 60)
grep -q 'old.jsonl' <<<"$out" && ok || bad "--days 60 should include old.jsonl: $out"

out=$("$SCRIPTS/collect.sh" --root "$root" --max 1)
[[ $(grep -c . <<<"$out") == 1 ]] && ok || bad "--max 1 should list 1 transcript, got: $out"

mkdir -p "$WORK/empty"
out=$("$SCRIPTS/collect.sh" --root "$WORK/empty"); rc=$?
[[ $rc == 0 && -z "$out" ]] && ok || bad "empty root should print nothing and exit 0 (rc=$rc, out=$out)"

"$SCRIPTS/collect.sh" --root "$WORK/missing" >/dev/null 2>&1; rc=$?
[[ $rc == 2 ]] && ok || bad "missing root should exit 2, got $rc"

echo "dream: target-ok.sh"
CLONE="$(cd "$SCRIPTS/../../../.." && pwd -P)"
home="$WORK/home" wc="$WORK/wc"
mkdir -p "$home/.claude/skills"
ln -s "$CLONE/claude/skills/commit" "$home/.claude/skills/shipped"

# expect <exit code> <path> [stderr substring]
expect() {
  local want="$1" path="$2" msg="${3:-}" err rc
  err=$(HOME="$home" WORK_CONTEXT="$wc" "$SCRIPTS/target-ok.sh" "$path" 2>&1 >/dev/null); rc=$?
  if [[ $rc != "$want" ]]; then bad "target-ok $path: exit $rc, want $want ($err)"
  elif [[ -n "$msg" && "$err" != *"$msg"* ]]; then bad "target-ok $path: stderr '$err' lacks '$msg'"
  else ok; fi
}
expect 0 "$wc/rules.d/learned.rules"
expect 0 "$home/.claude/rules/prs.md"
expect 0 "$home/.claude/skills/new-skill/SKILL.md"
expect 1 "$home/.claude/skills/shipped/SKILL.md" "$CLONE"
expect 1 "$home/.claude/CLAUDE.md"
expect 1 "$home/work-context/rules.d/x.rules"
expect 1 "$CLONE/claude/hooks/ban-patterns.rules"
expect 1 "$home/.claude/skills/SKILL.md"

echo "dream: $pass passed, $fail failed"
((fail == 0))
