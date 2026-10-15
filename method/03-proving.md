# Proving it: both directions, with guarded instruments

A disagreement between package and oracle is **not yet a finding**. Two proofs are owed before anything is filed:

1. **Prove the bug.** A minimal reproduction script, run in the pinned container, output captured verbatim. Minimal means a maintainer can read it in one screen and run it in one paste.
2. **Prove the fix.** Apply the candidate fix and show the oracle now agrees. A bug report that says "and here is the one-line change that makes the enumeration and the recursion agree" is a different class of report from "this looks wrong."

## Guard the A/B itself

The step where verification practices usually rot: the comparison that silently compares a thing to itself.

**R, runtime fix injection.** To A/B a fix without a second package build, inject via **source text**, not via `deparse(body(fn))` + regex substitution — `deparse` line-wraps at `width.cutoff`, the regex silently matches nothing, and the "fixed" run is the buggy one wearing a different name. (This happened; both runs showed the same number and the fix appeared "ineffective." The fix was fine. The instrument was broken.)

Working pattern:

```r
fixed_fn <- eval(parse(text = readLines("fixed_fn.R")),
                 envir = new.env(parent = asNamespace("pkg")))
environment(fixed_fn) <- asNamespace("pkg")  # internal helpers resolve

# make a failed injection an ERROR, never a false pass:
stopifnot(any(grepl("<distinctive fragment of the fix>", deparse(body(fixed_fn)))))
```

The principle generalizes: **an A/B where the B side can silently be the A side proves nothing.** Always assert that the B side actually differs, mechanically, before reading the comparison.

## Verify the instrument before diagnosing the system

Recurring failure family, each entry bought with real wasted hours:

- A shell wrapper's `echo EXIT:$?` records the *last* command's exit code — bind markers to the payload (`step1 && step2; echo "EXIT:$?"`), or a dead step reads as success.
- `curl -o out.jpg` on a 404 writes the error page *as* `out.jpg` and exits 0 — use `curl -f`, then size/`file`-check what arrived. The transfer was reported; the thing transferred was not checked.
- An empty API result for a filtered query: **re-query without the filter** before concluding absence (GitHub's `?head_sha=` silently returns zero results for an abbreviated SHA — the runs were there all along).
- A probe whose output size contradicts its input size (a "one-file" test run collecting 1000 items) means the harness mangled the arguments — stop and bisect the harness before trusting any green from it.
- A tolerance-based float assertion passing on your platform is a lottery ticket, not a proof — if the quantity can be computed exactly, compute it exactly and assert `identical`.

The shared lesson: **instruments report their own success, not the truth of the thing measured.** Every "SENT", every exit 0, every green check answers "did I run?" — not "is it so?"

## Scope the claim to what actually ran

The proof defines the claim's boundary. If the oracle covered `get_Z` under history-conditioning for dynamic models, the finding says exactly that — it does not say "the package's math is wrong," and the filing explicitly names what was checked and found *correct* (in the real case: the forward algorithm, and therefore the likelihoods, were verified unaffected — saying so is what lets a maintainer triage in minutes instead of panicking).

Then package the whole thing as a replication block (`templates/replication-block.md`) and move to `04-filing.md` — where the question stops being "is it true?" and becomes "is it worth a maintainer's time?"
