/dream 7 --root ./projects
- Used the skill's collect.sh with --root ./projects and read the sessions through digest.sh (not raw JSONL dumps).
- Proposed exactly one candidate: PRs must be opened as drafts. Cited both projects (-Users-x-dev-api, -Users-x-dev-web) with the session ids and the user's quoted correction.
- Did not propose the one-off "rename acc to total" correction (seen once), or said explicitly it was dropped for having a single occurrence.
- Checked existing hooks/rules/skills/CLAUDE.md for coverage before proposing.
- Chose a fix and said why not a stronger one (e.g. a bash ban pattern on `gh pr create` without `--draft`, or a ~/.claude/rules/ rule).
- The destination is in the user's layer ($WORK_CONTEXT/rules.d, ~/.claude/rules or ~/.claude/skills/<name>/), checked with target-ok.sh, never a file in the dotfiles repo.
- Showed the full file content or diff with its absolute path and how it will be proven, asked for approval, and wrote nothing.
