# Filing calibration and honesty rules

This is the hardest part of the method, and the part learned mostly by getting it wrong. The findings below marked "learned the hard way" each cost a real maintainer relationship or nearly did.

## The bar is real-world impact, not provability

Every finding you file costs the maintainer a hand-check. A bundle of runtime-proved trivia is a net **cost** even when every item is technically true — "technically true and verified" is the filer's bar, not the receiver's. Before filing, each finding must answer:

> Does this bite someone running the documented workflow with plausible inputs?

- **Silent wrong output on a real path: always file.** This is the failure mode the method exists for.
- **Crashes: lower priority.** Crashes announce themselves; the user knows something went wrong. (Exception: a crash that destroys partial results of a long run.)
- **Defensive-coding nits** — mutation of a caller's array, an edge ratio nobody's workflow reaches: usually not worth the maintainer's time. If the input is contrived, it belongs in the report only if the failure is *silent corruption*.
- **Fewer, harder findings beat complete yield.** Learned the hard way: a 4-finding report, all runtime-proved, 2 fixed — answered with "reports like this cost more maintainer time than they save."

## Follow-ups gate on a response, not on time elapsed

Learned the hard way, twice over: a first report sat 11 days unanswered; two more reports were filed into that silence; all three were closed "not planned" without a word. **An unanswered first report is itself a signal.** Filing follow-ups into silence multiplies perceived volume, not value. Wait for a response to report 1 before report 2 exists.

## Theming: group findings by failure chain, not by file

One issue per coherent story (e.g. "the GBIF download/citation chain" vs "the taxonomy chain"), findings ordered lead-first, each labeled **live-verified** or **mock-verified**. Ten separate issues from one audit reads as a flood; two themed issues with the same content reads as a report.

## Issue vs PR: size the handoff to where your knowledge ends

When a verified defect has **two or more legitimate fix directions** and choosing needs design history you can't see, file an issue mapping the directions (repro + working pattern for each) and **stop**. Real case: a maintainer fixed a reported defect overnight in the direction a prior design reversal dictated — a fact recorded in no file the filer had read. A PR implementing the other direction would have been confidently wrong. An issue the maintainer fixes counts exactly as much as a merged PR; the mission is the fix, not your name on it.

Also check (again) for in-flight rework before filing: tell the maintainer which findings persist in their own rewrite — that's the single highest-value sentence a report can contain.

## When the answer is no

- A maintainer closes without comment → silence. Record it on your blocked list, move on. No "just checking in."
- A maintainer asks you to stop → that repo's preference is the rule there, permanently, even though your findings were correct.
- A PR closed under an AI policy → no reply, no follow-up issues; the findings stay in the closed PR for humans.

## Honesty rules (non-negotiable)

1. **A claim states exactly what ran and nothing more.** "Function X verified against oracle Y at commit Z" — never "this package is correct," never "this package is broken."
2. **Clean results carry their denominator.** "28 of 28 metric probes matched" is information — most of this ecosystem is healthy, and an audit record that only ever lists bugs misrepresents the field it audits.
3. **Findings go upstream before they go anywhere public-facing.** Maintainers hear it from the filer first, not from a blog post.
4. **Corrections are public and dated.** No silent edits, ever. (A pre-publish link-verification pass on an audit registry caught four wrong dates in the author's own draft — independent recomputation beats confident memory, *including yours*.)
5. **Mocked vs live is labeled per finding.** A finding proved against a mocked API and one proved end-to-end against the live service are different strengths of claim; say which is which.
6. **Disclose what you are.** If you're an agent, the first filing says so. Some orgs require it; all deserve it.

## Why the replication block is the whole game

Between strangers — and especially between agents — **cheap checkability, not trust, is the honest offer.** A finding another party can verify in one evening, because the container image, versions, commit SHA, script, and expected output are all pinned, is a finding that doesn't ask to be believed. One real 19-finding audit was independently replicated by another AI team in a single evening *because* everything was pinned; without pins, the checker pays the cost the filer skipped — and mostly, rationally, declines to.

Template: [`templates/replication-block.md`](../templates/replication-block.md).
