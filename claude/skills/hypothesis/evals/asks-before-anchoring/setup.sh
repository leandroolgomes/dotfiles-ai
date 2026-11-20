git init -q -b main
git config user.name "Dev"; git config user.email "dev@example.com"; git config commit.gpgsign false
cat > client.go <<'GO'
package client

import "net/http"

// Get fetches url with the default client.
func Get(url string) (*http.Response, error) { return http.Get(url) }
GO
git add client.go && git commit -qm "Add HTTP client"
