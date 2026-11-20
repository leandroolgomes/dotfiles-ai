---
name: blast-radius
description: Find what a change could break outside its diff, and prove the one fact its safety rests on by running real code instead of arguing it. Use when the user says /blast-radius, "what could this break", or asks to review a small diff they don't trust.
disable-model-invocation: true
---

Listing the callers is not the job; grep does that in a second. The job is the breakage grep won't show, and a
writeup that sounds right is worth nothing until code has run. Report only. Don't fix anything.

## How sure is each claim

Get every fact the change's safety depends on as far down this list as is cheap, and say where it stopped:

1. **Said so.** Worthless on its own.
2. **Pointed at it.** A real `file:line`, or the library's own source at the pinned version.
3. **Walked it.** Followed the failure step by step and showed it can't reach.
4. **Ran it.** A test or script that calls the real code and fails loud if the claim is wrong.
5. **Reproduced it** in the running app (the project's `verify` skill, if it has one).

## Steps

1. **Scope.** What the user names; otherwise the branch diff from its merge base with the default branch,
   plus uncommitted changes. Say what you took.
2. **Read the change**, including what it now does that the diff doesn't spell out: changed defaults, error
   paths, ordering, edge-case inputs (empty, nil, duplicates, whitespace, very large).
3. **Find the one fact it's safe because of.** Most risky-looking changes are safe because of a single fact
   ("every caller passes trimmed input", "this only drops entries that already expired"). Spend the time here,
   not on a long list of maybes. If no single fact covers it, name the two or three that do.
4. **Look where grep stops:** the library source at the version in the lock file; when things run (goroutines,
   defer, teardown, retries); data that crosses a boundary (JSON fields, DB columns, queue messages, files, env
   vars, feature flags, another service reading the same bytes); callers two or three hops away.
5. **Prove the fact (level 4).** Write a throwaway test or script next to the code (`*_blast_test.go`,
   `scripts/blast-*.sh`, a temp dir), run it, keep the exact command and output. If it fails, that is the
   headline finding. Delete the scratch files afterwards unless the user wants them as a regression test.
6. **Rate each other risk** with how it breaks, `file:line`, how likely and how bad. A search that finds
   nothing is an answer; say what you searched. Never invent a caller or an API.

## Reply

- **What changed**, including the non-obvious part.
- **Safe because:** the fact, the level it reached, and the command plus output that proves it, or
  `unproven` and why.
- **Risks:** confirmed ones first, each with `file:line`, likelihood, cost and the check that shows it.
- **Cleared:** what you checked that is fine, and how.
- **Before merging:** the cheapest test that would catch the real bug, as code the user can paste.
