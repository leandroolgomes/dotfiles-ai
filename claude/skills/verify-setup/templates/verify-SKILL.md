---
name: verify
description: Run <app> for real and prove a change works or reproduce a bug: start it, drive the feature, observe output, stop it. Use after changing behavior, before saying done, and when a bug report comes in. FEATURE_MAP.md says how to reach every feature.
---

## Start
```sh
<exact command(s) to start dependencies and the app; how to know it is ready>
```

## Doctor
Run before the first drive and again after anything surprising (a failed check, a hang, odd output).
Read-only; exits non-zero when the instance is not worth driving.
```sh
<process up, the build you just made (not an old one), port owned by the process you started, deps ready>
```

## Drive and observe
- Find the feature in `FEATURE_MAP.md` (same directory). Use its check command.
- Logs: <where they go / command to tail>
- State: <how to inspect the DB / queue / files the app writes>
- Evidence goes to `<dir outside the app's data dir, e.g. $TMPDIR/verify-<app>/<timestamp>/>`: the command, its
  output and the resulting state for each check.
- Verdict per check: VERIFIED, NOT VERIFIED (it ran and showed the failure) or INCONCLUSIVE (it could not
  show either). Inconclusive is not a pass.

## Stop and clean up
```sh
<exact command(s) that stop what Start started, by PID or container name; never by process name>
```
Then confirm nothing is left running and the evidence directory still exists.

## Reproducing a bug report
1. Map the report to a feature in `FEATURE_MAP.md`, even if it is vague (a screenshot, "X is broken").
2. Reproduce on the current branch first; then on the default branch (`git stash` or a worktree) to tell
   "already fixed" from "still broken".
3. Report: reproduced yes/no, exact steps and output, the code paths from the map, and a suspected cause
   with the evidence for it. Say "not reproduced" plainly; don't guess a fix.

## Known limits
<what this skill cannot verify here and why, e.g. needs a real AWS account>
