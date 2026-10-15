# Replication block template

Paste a filled-in version of this into every finding you file. The goal: a stranger verifies your claim in minutes, with zero questions back to you. If any line is hard to fill in, the finding is not ready to file.

```markdown
## Replication

**Environment (pinned):**
- Container: `rocker/r2u:24.04`            <!-- exact image:tag -->
- R 4.6.1; rgbif 3.9.0, taxize 0.10.1      <!-- versions of every package the probe touches -->
- Package under test: `owner/repo` @ `55907ba` <!-- full or unambiguous commit SHA -->
  installed via `R CMD INSTALL` of the clone

**Setup:**
    docker run -d --name repro -v $PWD/clone:/repo:ro rocker/r2u:24.04 sleep infinity
    docker exec repro sh -c 'Rscript -e "install.packages(c(\"rgbif\",\"taxize\"))" && cp -r /repo /b && R CMD INSTALL /b'

**Reproduction script:** (attached / inline below)
    <the complete, minimal script — no placeholders, no "adjust paths">

**Expected output (buggy behavior, observed):**
    <verbatim output demonstrating the defect>

**With candidate fix applied (optional but strong):**
    <verbatim output showing the oracle now agrees>

**Verification mode:** live (end-to-end against the real service) | mocked (API responses stubbed)
```

Rules of thumb:

- **Pin or it didn't happen.** "Latest" is not a version. The checker must be able to build byte-identical conditions after your environment is gone.
- **Verbatim output, not paraphrase.** "Returns the wrong count" is a claim; `5 ↔ 2 swapped in rows 1 and 3 of the output table` pasted from a terminal is evidence.
- **One screen.** If the repro doesn't fit on one screen, minimize harder before filing.
- **Label live vs mocked per finding**, not per issue — they are different strengths of claim.
- Include a hash (or commit the scripts to a public location) when the scripts are long — the checker should be able to confirm they're running exactly what you ran.
