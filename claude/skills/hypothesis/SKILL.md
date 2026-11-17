---
name: hypothesis
description: Critical-thinking loop. Before a task, the user writes their own guess, risk and proof (HYPOTHESIS.md); the agent works to that finish line and reports the decisions it made. Use when the user says /hypothesis, /hypothesis close or /hypothesis status.
disable-model-invocation: true
---

A hypothesis keeps the user doing the thinking: their guess comes first, proof is the finish line, and they read
the agent's decisions instead of the whole diff. `HYPOTHESIS.md` lives at the git root (globally git-ignored).
A Stop hook (`hypothesis-proof-gate.sh`) blocks "done" while `status: active` and proof is missing.

## `/hypothesis <task>`: open a hypothesis

1. If `HYPOTHESIS.md` already exists with `status: active`, show it and ask whether to continue it or close it first.
2. Ask the user, in one message, for their own answers. **Do not suggest a guess, risk or approach before
   they answer**: anchoring them defeats the point.
   - **My guess:** how they think it should be done, or what the cause is
   - **Biggest risk:** what is most likely to go wrong
   - **Would change my mind:** what evidence would make them drop the guess
   - **Done means:** the proof they want (numbers, commands, behaviors)
3. After they answer, propose extra proof items and wait for approval. Make each one checkable by a command.
   Pull them from `~/work-context/standards/` and `~/work-context/incidents/` if those exist, and from the
   repo's test, lint and build commands. Add a rollback or flag-off check for risky changes.
4. Write `HYPOTHESIS.md` at the git root (`git rev-parse --show-toplevel`) using the template below, then start the task.

## While working

- Work toward the proof items, not only "tests pass". Don't write tests that just confirm your own choices:
  proof should exercise the user's risk.
- Record every decision the user did not specify (data model, defaults, limits, libraries, semantics such as
  at-least-once) as you go.
- If evidence contradicts the user's guess, say so in plain words. Don't bend the work to fit the guess.

## Before stopping: the report

- Check each proof item and put the evidence on indented lines under it: the command you ran and the key
  output (counts, numbers, pass/fail). If an item can't be proven here (no credentials, no environment),
  mark it `- [!]` with the reason. Never check an item without having run it.
- Fill **Hypothesis vs. what I did**: for the guess, the risk and "would change my mind", say AGREED, DIFFERENT
  (and why) or N/A.
- Fill **Decisions you didn't make**: one line each, `Dn. choice | alternatives | why`. Flag with ⚠️ any
  decision that changes a contract for others (API, semantics, data retention, cost). Write `none` if there were none.
- In chat, give a short summary and point at `HYPOTHESIS.md`. Don't paste it.

## `/hypothesis status`

Show proof progress (`n/m` checked, `[!]` count) and the decisions so far.

## `/hypothesis close`

1. Ask the user for a verdict on their guess and risk: right, partly or wrong, plus what they missed.
   Propose one from the report, but the user decides.
2. Append one line to `~/work-context/calibration.md` (create it with a `# Calibration` heading if missing):
   `YYYY-MM-DD  <slug>  guess: ✅|〰️|❌  risk: ✅|〰️|❌  missed: <short>`
3. Set `status: closed`, move the file to `~/work-context/hypothesiss/YYYY-MM-DD-<slug>.md` and confirm the path.

## Template

```markdown
---
status: active
created: YYYY-MM-DD
slug: short-kebab-name
---
# Hypothesis: <task>

## My guess
<user's words>

## Biggest risk
<user's words>

## Would change my mind
<user's words>

## Done means (proof)
- [ ] <checkable item>
- [ ] <checkable item>

## Report
### Hypothesis vs. what I did
<filled by the agent before stopping>

### Decisions you didn't make
<filled by the agent before stopping>
```
