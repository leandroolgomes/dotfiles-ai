#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit): format the edited file and lint it right away, using only the
# tools and configs the repo already has (so it follows each company's setup). Never installs or
# downloads anything; a missing tool is skipped. Lint errors go back to Claude (exit 2 + stderr).
# Disable for a session with CLAUDE_FORMAT_ON_EDIT=0.
set -uo pipefail

[[ "${CLAUDE_FORMAT_ON_EDIT:-1}" == 0 ]] && exit 0
command -v jq >/dev/null || exit 0
file=$(jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
[[ -f "$file" ]] || exit 0
dir=$(cd "$(dirname "$file")" && pwd)
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo "$dir")

# up <name...>: first path matching one of the names, from the file's dir up to the repo root
up() {
  local d="$dir" n
  while :; do
    for n in "$@"; do [[ -e "$d/$n" ]] && { echo "$d/$n"; return 0; }; done
    [[ "$d" == "$root" || "$d" == / ]] && return 1
    d=$(dirname "$d")
  done
}

problems=""
report() { problems+="$1"$'\n'"$(head -n 40 <<<"$2")"$'\n'; }

case "$file" in
  *.go)
    if command -v goimports >/dev/null; then out=$(goimports -w "$file" 2>&1) || report "goimports $file" "$out"
    elif command -v gofmt >/dev/null; then out=$(gofmt -w "$file" 2>&1) || report "gofmt $file" "$out"; fi
    ;;
  *.js|*.jsx|*.mjs|*.cjs|*.ts|*.tsx|*.vue|*.svelte|*.css|*.scss)
    bin=$(up node_modules/.bin) || bin=""
    if [[ -n "$bin" && -x "$bin/prettier" ]] && up .prettierrc .prettierrc.json .prettierrc.js .prettierrc.cjs .prettierrc.mjs .prettierrc.yaml .prettierrc.yml prettier.config.js prettier.config.cjs prettier.config.mjs >/dev/null; then
      out=$("$bin/prettier" --write --log-level warn "$file" 2>&1) || report "prettier $file" "$out"
    fi
    if [[ -n "$bin" && -x "$bin/eslint" && "$file" != *.css && "$file" != *.scss ]]; then
      out=$(cd "$root" && "$bin/eslint" --fix "$file" 2>&1) || report "eslint $file" "$out"
    fi
    ;;
  *.py)
    ruff=$(up .venv/bin/ruff) || ruff=$(command -v ruff) || ruff=""
    if [[ -n "$ruff" ]]; then
      "$ruff" format -q "$file" >/dev/null 2>&1
      out=$(cd "$root" && "$ruff" check -q --fix "$file" 2>&1) || report "ruff check $file" "$out"
    fi
    ;;
  *.java)
    command -v google-java-format >/dev/null && { out=$(google-java-format -i "$file" 2>&1) || report "google-java-format $file" "$out"; }
    ;;
  *.lua)
    command -v stylua >/dev/null && up stylua.toml .stylua.toml >/dev/null && { out=$(stylua "$file" 2>&1) || report "stylua $file" "$out"; }
    ;;
esac

# Shell scripts, by extension or shebang (dotfiles' bin/ scripts have no extension).
if [[ "$file" == *.sh || "$file" == *.bash ]] || head -n1 "$file" 2>/dev/null | grep -Eq '^#!.*(ba|da|k)?sh( |$)'; then
  head -n1 "$file" | grep -q zsh || { command -v shellcheck >/dev/null && { out=$(shellcheck -S warning "$file" 2>&1) || report "shellcheck $file" "$out"; }; }
fi

[[ -z "$problems" ]] && exit 0
printf 'format-on-edit.sh found problems in the file you just edited; fix them:\n%s' "$problems" >&2
exit 2
