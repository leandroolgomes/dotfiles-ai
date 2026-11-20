# Report only: the branch is unchanged and nothing was committed.
set -u
[ "$(git rev-parse HEAD)" = "$(git rev-parse tidy-fields)" ] || { echo "FAIL: HEAD moved"; exit 1; }
[ "$(git rev-list --count HEAD)" -eq 2 ] || { echo "FAIL: new commits were made"; git log --oneline; exit 1; }
git diff --quiet HEAD -- fields.go report.go || { echo "FAIL: changed the code under review"; git diff --stat; exit 1; }
echo pass
