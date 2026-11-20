#!/usr/bin/env bash
# target-ok.sh: may /dream write to PATH? Only into the user's own layer, never into the dotfiles clone this
# script ships in (not even through a symlink such as a shipped skill under ~/.claude/skills).
#
# Usage: target-ok.sh PATH
#   exit 0: allowed; prints the resolved path
#   exit 1: refused; the reason is on stderr
# Allowed: $WORK_CONTEXT/rules.d/ (default ~/work-context), ~/.claude/rules/, ~/.claude/skills/<name>/.
set -euo pipefail

[[ $# == 1 && -n "$1" ]] || { echo "usage: target-ok.sh PATH" >&2; exit 2; }
refuse() { echo "target-ok: refused $1: $2" >&2; exit 1; }

# resolve PATH: the nearest ancestor that exists or is a symlink (even a dangling one), resolved with
# readlink -f (follows every link), plus the part that doesn't exist yet
resolve() {
  local p="$1" tail=""
  [[ "$p" == /* ]] || p="$PWD/$p"
  [[ "/$p/" == *"/../"* || "/$p/" == *"/./"* ]] && return 1
  while [[ ! -e "$p" && ! -L "$p" ]]; do tail="/$(basename "$p")$tail"; p="$(dirname "$p")"; done
  echo "$(readlink -f "$p")$tail"
}

target="$(resolve "$1")" || refuse "$1" "relative segments (. or ..) are not allowed"
clone="$(readlink -f "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../../../..")"
[[ "$target/" == "$clone/"* ]] && refuse "$1" "it resolves into the dotfiles clone $clone ($target)"

claude="$(resolve "$HOME/.claude")"
wc="$(resolve "${WORK_CONTEXT:-$HOME/work-context}")"
case "$target" in
  "$wc"/rules.d/?*|"$claude"/rules/?*) ;;
  "$claude"/skills/*/?*) ;;
  *) refuse "$1" "not in the user's layer (\$WORK_CONTEXT/rules.d, ~/.claude/rules, ~/.claude/skills/<name>/)";;
esac
echo "$target"
