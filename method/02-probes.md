# The two probe kinds

## 1. Docs-vs-code: every documented claim is a testable assertion

Does the documented parameter exist? Does the documented call run? Does the example produce the documented output? Dead documented API paths are real findings — a researcher following the docs hits them before anything else. (One real audit found 13 dead documented API paths in a single package.)

**Verify at runtime, not by static analysis.** The mechanisms that silently defeat static docs-checking, all encountered in real audits:

Python:
- attrs/dataclass inheritance and underscore-aliases (`_rvec` becomes init arg `rvec`),
- `lazy_loader` mappings and PEP 562 module `__getattr__` (the symbol exists at runtime, no grep will find it),
- decorators that rewrite signatures.

The honest check is `pip install` the clone in a container, then `inspect.signature()` / `getattr()` against each documented claim. Static reading flagged 54 mismatches in one library; runtime confirmed 3.

R:
- `exists("x")` inside a package function falls through to the **search path**: any attached package exporting that name silently satisfies it (`data.table::key` once permanently disabled an `if (!exists(...))` error guard). The guard measures the wrong scope — only runtime shows it.
- Argument forwarding by name: in any wrapper doing `foo(x = args$x, y = args$y, ...)`, scan for `name = args$other` mismatches. In one real client library, all 4 such mismatches were silent filter-drop bugs the test suite never caught.
- **Nonexistent-value probes make silent drops visible**: query with a filter value that matches nothing. A working filter returns 0; a silently dropped filter returns the unfiltered total. Cheap, decisive, no oracle needed.
- Check error-handling branches too: `is.nan()` on a character vector returns `FALSE` rather than erroring — an "obvious crash" read from the source may not exist at runtime. (This exact wrong guess was caught by a probe minutes before it would have been filed as a false claim.)

## 2. Math-vs-oracle: the core of the method

The package's own tests usually cannot catch silent wrong output, because the tests were written by the same hands under the same assumptions as the code. The comparison target must come from **outside the implementation** — an *oracle*: an independent recomputation from first principles, deliberately dumb, so simple it is self-evidently correct.

**Slow and obvious beats fast and clever, because the point is to disagree with clever.**

Three oracle patterns, each with the real bug it caught:

### Brute-force enumeration
When the clever code computes something over a space small enough to enumerate, enumerate it. An occupancy package computed P(species present | detection history) with an efficient backward recursion; the oracle enumerated **all 2^n latent histories**, computed each probability straight from the model definition, and summed. They disagreed: the recursion applied a matrix product in the wrong order — wrong for every dynamic model with ≥3 seasons ([flocker #118](https://github.com/jsocolar/flocker/issues/118)). The package's own unit test passed, because it happened to use the one parameter family where the bug cancels exactly.

Runnable version: [`examples/enumeration-oracle/`](../examples/enumeration-oracle/).

### Hand-countable inputs
Make the input so small the right answer is beyond argument. A range-map evaluator was fed a raster where the confusion matrix could be counted on fingers — *this* cell is a true positive, *that* one a false negative, so TSS must be exactly *this number*. It returned something else: a misaligned NA mask shifted which cells were compared, enough to flip the score's sign ([gbif.range #28](https://github.com/8Ginette8/gbif.range/issues/28)).

### Definitional recomputation
Recompute the index/metric from its published formula in a few lines of straightforward code (the paper's Equation 1, transcribed naively), and compare on fixed small inputs. Numerical caution: when the definitional form allows it, compute differences directly rather than expanded forms like a²+b²−2ab — cancellation noise in the *oracle* otherwise becomes a platform lottery at tight tolerances.

## When probe and test disagree: the test is a claim, not an oracle

A passing test can encode the very bug it should catch. A coordinate parser swapped latitude and longitude; the package had a test for exactly that path — passing, because the test constructed its input with the *same* swap ([galah-R #306](https://github.com/AtlasOfLivingAustralia/galah-R/pull/306)). When a runtime probe contradicts a green test, **read how the test builds its input** before trusting either side.

## The common shape

Recompute the answer in a way that shares **no code and no assumptions** with the implementation; make the input small enough that the right answer is beyond argument; treat any disagreement as a finding **to prove** — in both directions (`03-proving.md`) — never as a finding to file as-is.
