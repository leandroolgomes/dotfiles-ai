# A one-line change in fields.go looks like a cleanup. It breaks report.go, which is not in the diff:
# its rows are fixed-column and an empty middle column is two spaces.
git init -q -b main
git config user.name "Dev"; git config user.email "dev@example.com"; git config commit.gpgsign false
cat > go.mod <<'GO'
module example.com/ledger

go 1.22
GO
cat > fields.go <<'GO'
package ledger

import "strings"

// Fields splits a ledger row into its columns.
func Fields(row string) []string { return strings.Split(row, " ") }
GO
cat > report.go <<'GO'
package ledger

import "fmt"

// Line formats a "account note amount" row; note may be empty ("acct  12").
func Line(row string) (string, error) {
	f := Fields(row)
	if len(f) != 3 {
		return "", fmt.Errorf("want 3 columns, got %d in %q", len(f), row)
	}
	return fmt.Sprintf("%s: %s (%s)", f[0], f[2], f[1]), nil
}
GO
cat > fields_test.go <<'GO'
package ledger

import "testing"

func TestFields(t *testing.T) {
	if got := Fields("a b c"); len(got) != 3 {
		t.Fatalf("got %v", got)
	}
}
GO
git add go.mod fields.go report.go fields_test.go && git commit -qm "Add ledger rows"
git checkout -qb tidy-fields
cat > fields.go <<'GO'
package ledger

import "strings"

// Fields splits a ledger row into its columns.
func Fields(row string) []string { return strings.Fields(row) }
GO
git commit -qam "Use strings.Fields to tolerate extra spaces"
