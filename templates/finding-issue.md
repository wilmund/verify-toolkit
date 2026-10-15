# Finding-issue template

One issue per coherent failure chain (not per file, not per finding). Lead with the highest-impact item. Every finding carries its own evidence; the replication block covers them all.

```markdown
Title: <subsystem>: <lead finding in plain words> (+ N related findings, all runtime-verified)

<!-- Disclosure, if you are an agent — first line, matter-of-fact: -->
*I'm an autonomous AI agent ([who/what link]); everything below was verified at
runtime in a pinned container, scripts included. Happy to turn any of these
into a PR, or leave them with you — whichever helps.*

## Summary

<2–4 sentences: what workflow is affected, what a user experiences, why it's
silent (if it is). State the real-world consequence first — "citation counts
in the table users paste into papers are attributed to the wrong datasets" —
and the mechanism second.>

| # | Finding | Severity | Verified |
|---|---------|----------|----------|
| 1 | <one line> | silent wrong output | live |
| 2 | <one line> | crash on documented path | mocked |

## 1. <Lead finding>

**What happens:** <observed behavior, verbatim output excerpt>
**Why:** <mechanism, file:line, the specific expression>
**Impact:** <who hits this, doing what documented thing>
**Fix direction:** <one-liner if single obvious direction; if 2+ legitimate
directions, map each with a working pattern and explicitly leave the choice —
see 04-filing.md on sizing the handoff>

## 2. <Next finding> …

## What I checked and found correct

<The denominator. Name the adjacent things verified clean — "the forward
algorithm (and therefore all likelihood computations) agrees with the oracle" —
so triage starts scoped, not panicked.>

## Replication

<the filled-in replication block>
```

Notes:

- **Ordering = impact order**, not discovery order.
- **The "found correct" section is not optional.** It is the difference between a report and an alarm.
- If the project has an in-flight rewrite, add a section: *which of these persist on `<branch>` @ `<sha>`* — checked, not guessed.
- Offer a PR only when the gates allow it (no CLA block, AI policy permits) and the fix direction is singular.
