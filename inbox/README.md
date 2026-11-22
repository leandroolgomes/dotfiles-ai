# agent-inbox

One queue of what needs you: blocked or finished agents, review requests, red CI, and any source you
connect later. Run `agent-inbox`, `agent-inbox doctor`, `agent-inbox init`.

## Layout

| Path | What | Where it lives |
|---|---|---|
| `bin/agent-inbox` | Core: runs sources in parallel, applies rules, renders | dotfiles (public) |
| `inbox/sources.d/` | Generic sources: `tuios`, `herdr`, `herdr-app`, `github` | dotfiles (public) |
| `~/work-context/inbox/sources.d/` | Company sources (Jira, PagerDuty, internal tools) | private |
| `~/work-context/inbox/config.toml` | Per-source settings (hosts, repos, `enabled`) | private |
| `~/work-context/inbox/rules.toml` | What counts as "needs me" | private |

Set `AGENT_INBOX_HOME` to move the private folder. A private source with the same name as a built-in one
replaces it.

## Adding a source

1. `cp inbox/adapter-template ~/work-context/inbox/sources.d/<name> && chmod +x` it.
2. Authenticate yourself (the tool's CLI login, or a token in the Keychain).
3. Add `[sources.<name>]` to `config.toml` if it needs settings.
4. `agent-inbox doctor` until it shows ✅, then add rules for its `kind`s.

## Adapter contract

An adapter is any executable. It is called with one argument:

| Call | Must do |
|---|---|
| `<name> check` | Exit 0 and print one status line, or exit **3** with the fix command on stderr when it isn't set up or authenticated. Any other exit is an error. |
| `<name> items` | Print one JSON object per line and exit 0. Errors go to stderr. |

Each call has 15s (`AGENT_INBOX_TIMEOUT`). A slow or broken source is reported and skipped; the others
still show. `$AGENT_INBOX_SOURCE_CONFIG` holds the source's `config.toml` table as JSON.

Item fields (only `title` is required):

```json
{"source":"github","kind":"review","id":"…","title":"org/api#42 Fix retry","detail":"by alice",
 "url":"https://…","action":"what to run","age_min":95,"tags":["release-blocker"],"hint":"today"}
```

`hint` (`now`, `today`, `done`, `fyi`, `ignore`) is the level used when no rule matches.

## Rules

`rules.toml` is a list of `[[rule]]` tables; the first match wins. Match keys: `source`, `kind`, `owner`,
`tag`, `title_regex`, `min_age_min`. See `inbox/rules.default.toml`.

## Credentials

Never in this repo or in `config.toml`. Sources read your own CLI logins (`gh auth login`, `aws sso login`)
or the Keychain (`security find-generic-password -s agent-inbox/<name> -w`).
