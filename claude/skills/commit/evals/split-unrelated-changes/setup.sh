# A repo with two unrelated uncommitted changes: a bug fix and a docs typo.
git init -q -b main
git config user.name "Dev"; git config user.email "dev@example.com"; git config commit.gpgsign false
cat > calc.go <<'GO'
package calc

// Add returns the sum of a and b.
func Add(a, b int) int { return a - b }
GO
printf '# calc\n\nInstalation: go get example.com/calc\n' > README.md
git add calc.go README.md && git commit -qm "Initial commit"
sed -i.bak 's/return a - b/return a + b/' calc.go && rm calc.go.bak
sed -i.bak 's/Instalation/Installation/' README.md && rm README.md.bak
