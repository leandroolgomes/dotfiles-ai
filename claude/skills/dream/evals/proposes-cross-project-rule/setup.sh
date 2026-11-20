#!/usr/bin/env bash
# Two projects where the user corrects the same thing (PRs must be drafts), plus a one-off correction.
git init -q -b main
git config user.name "Dev"; git config user.email "dev@example.com"; git config commit.gpgsign false
mkdir -p projects/-Users-x-dev-api projects/-Users-x-dev-web
pr_session() {   # pr_session <title>: agent opens a ready PR, user corrects it
  local t="$1"
  jq -cn '{type:"user", message:{content:"open a PR for this branch"}}'
  jq -cn --arg c "gh pr create --title \"$t\" --body \"...\"" \
    '{type:"assistant", message:{content:[{type:"tool_use", name:"Bash", input:{command:$c}}]}}'
  jq -cn '{type:"user", message:{content:"no, always open PRs as draft (--draft). I said this before"}}'
  jq -cn --arg c "gh pr close 12 && gh pr create --draft --title \"$t\" --body \"...\"" \
    '{type:"assistant", message:{content:[{type:"tool_use", name:"Bash", input:{command:$c}}]}}'
}
pr_session "Add retry to payments client" > projects/-Users-x-dev-api/a.jsonl
pr_session "Fix header layout on mobile" > projects/-Users-x-dev-web/b.jsonl
{
  jq -cn '{type:"user", message:{content:"sum the invoice lines"}}'
  jq -cn '{type:"assistant", message:{content:[{type:"text", text:"Added sumLines() with variable acc."}]}}'
  jq -cn '{type:"user", message:{content:"rename acc to total"}}'
} > projects/-Users-x-dev-api/c.jsonl
git add projects && git commit -qm "Session logs"
touch .start
