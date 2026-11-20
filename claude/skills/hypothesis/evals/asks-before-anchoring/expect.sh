# The first turn must only ask: no HYPOTHESIS.md yet and no code changes.
[ ! -f HYPOTHESIS.md ] || { echo "FAIL: wrote HYPOTHESIS.md before the user answered"; exit 1; }
git diff --quiet || { echo "FAIL: changed code before the user answered"; git diff --stat; exit 1; }
echo pass
