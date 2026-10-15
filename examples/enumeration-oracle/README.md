# Enumeration oracle — runnable example

A complete, self-contained demonstration of the brute-force-enumeration oracle pattern, using the bug shape from a real finding ([flocker #118](https://github.com/jsocolar/flocker/issues/118), accepted by the maintainer for the fix release).

```sh
Rscript oracle.R
# or, pinned:
docker run --rm -v $PWD:/x:ro rocker/r2u:24.04 Rscript /x/oracle.R
```

What it shows, in ~100 lines of base R:

1. **The oracle**: smoothed occupancy probabilities computed by enumerating all 2^n latent histories straight from the model definition — deliberately dumb, self-evidently correct.
2. **The clever code**: a forward-backward recursion, in two variants — correct (`T %*% (e * beta)`) and the real published bug (`(T %*% e) * beta`).
3. **The disagreement**: with generic parameters the buggy recursion is wrong at every timestep except the last two (which is why short, shallow tests miss it):

   ```
     t   oracle correct_FB buggy_FB
   1 1 0.866170   0.866170 0.881168
   2 2 0.748785   0.748785 0.730567
   3 3 0.873137   0.873137 0.873137
   4 4 0.113673   0.113673 0.113673
   ```

4. **The trap**: with `ex = 1 - colo` the chain is memoryless and the bug cancels *exactly* — buggy equals correct to machine precision. A unit test written in that parameter family is green with the bug present. In the real package, the unit test used exactly that family. **The test is a claim, not an oracle; the enumeration is the oracle.**

The `stopifnot()` calls make the script its own proof: it errors if the correct recursion ever disagrees with the enumeration, or if the bug ever becomes invisible outside the cancelling family.

Transfer the pattern: anywhere code computes a quantity over a space you can enumerate (latent state sequences, permutations of a small vector, all cells of a tiny raster, all pairs in a small set), the enumeration is cheap to write, impossible to get subtly wrong, and shares no assumptions with the implementation. That independence is the entire value.
