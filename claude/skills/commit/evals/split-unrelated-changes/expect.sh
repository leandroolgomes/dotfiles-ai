# Two concerns → at least two commits, none mixing them, nothing left uncommitted, nothing pushed.
set -u
n=$(git rev-list --count HEAD); echo "commits: $n"
[ "$n" -ge 3 ] || { echo "FAIL: expected the two changes in separate commits"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "FAIL: uncommitted changes left"; git status --short; exit 1; }
for c in $(git rev-list HEAD~$((n - 1))..HEAD); do
  files=$(git show --name-only --format= "$c" | sort | tr '\n' ' ')
  echo "$c: $files"
  case "$files" in *README.md*calc.go*|*calc.go*README.md*) echo "FAIL: one commit mixes both concerns"; exit 1;; esac
done
echo pass
