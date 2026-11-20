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

# Many sessions: the cap must not turn a long listing into a SIGPIPE exit.
many="$WORK/many/-Users-x-dev-$(printf 'p%.0s' {1..80})"; mkdir -p "$many"
for i in $(seq 1 700); do : >"$many/session-$(printf 'x%.0s' {1..40})-$i.jsonl"; done
out=$("$SCRIPTS/collect.sh" --root "$WORK/many" 2>/dev/null); rc=$?
[[ $rc == 0 && $(grep -c . <<<"$out") == 10 ]] && ok || bad "700 sessions: want exit 0 and 10 lines (per-project cap), got rc=$rc, $(grep -c . <<<"$out") lines"

# One busy project must not push out the others; truncation is reported on stderr.
busy="$WORK/busy"; mkdir -p "$busy/-Users-x-dev-quiet" "$busy/-Users-x-dev-busy"
: >"$busy/-Users-x-dev-quiet/q.jsonl"; touch -t "$(date -v-1d '+%Y%m%d%H%M')" "$busy/-Users-x-dev-quiet/q.jsonl"
for i in 1 2 3 4 5; do : >"$busy/-Users-x-dev-busy/b$i.jsonl"; done
out=$("$SCRIPTS/collect.sh" --root "$busy" --max 3 --per-project 2 2>"$WORK/err")
grep -q 'q.jsonl' <<<"$out" && ok || bad "--per-project 2 should keep the quiet project: $out"
[[ $(grep -c . <<<"$out") == 3 ]] && ok || bad "--max 3 should list 3, got: $out"
grep -q 'kept 3 of 6' "$WORK/err" && ok || bad "truncation should be reported on stderr, got: $(cat "$WORK/err")"
newest=$("$SCRIPTS/collect.sh" --root "$busy" --max 1 2>/dev/null | cut -f2)
[[ "$newest" == "$busy/-Users-x-dev-busy/"* ]] && ok || bad "--max 1 should keep the newest transcript, got: $newest"

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
# Dangling links into the clone (a shipped file or skill removed upstream) must still be refused.
mkdir -p "$home/.claude/rules"
ln -s "$CLONE/claude/rules-gone/x.md" "$home/.claude/rules/dangling.md"
expect 1 "$home/.claude/rules/dangling.md" "$CLONE"
ln -s "$CLONE/claude/skills/not-yet" "$home/.claude/skills/ghost"
expect 1 "$home/.claude/skills/ghost/SKILL.md" "$CLONE"

echo "dream: $pass passed, $fail failed"
((fail == 0))
