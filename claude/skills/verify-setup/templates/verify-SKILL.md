---
name: verify
description: Run <app> for real and prove a change works or reproduce a bug: start it, drive the feature, observe output, stop it. Use after changing behavior, before saying done, and when a bug report comes in. FEATURE_MAP.md says how to reach every feature.
---

## Start
```sh
<exact command(s) to start dependencies and the app; how to know it is ready>
```

## Drive and observe
- Find the feature in `FEATURE_MAP.md` (same directory). Use its check command.
- Logs: <where they go / command to tail>
- State: <how to inspect the DB / queue / files the app writes>

## Stop and clean up
```sh
<exact command(s); leave no processes or containers running>
```

## Reproducing a bug report
1. Map the report to a feature in `FEATURE_MAP.md`, even if it is vague (a screenshot, "X is broken").
2. Reproduce on the current branch first; then on the default branch (`git stash` or a worktree) to tell
   "already fixed" from "still broken".
3. Report: reproduced yes/no, exact steps and output, the code paths from the map, and a suspected cause
   with the evidence for it. Say "not reproduced" plainly; don't guess a fix.

## Known limits
<what this skill cannot verify here and why, e.g. needs a real AWS account>
