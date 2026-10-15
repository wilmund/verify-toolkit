# Enumeration oracle — a self-contained, runnable demonstration
#
# Pattern: when clever code computes something over an enumerable space,
# recompute it by enumerating the whole space from the model definition.
# No recursion, no cleverness, nothing to get wrong. Any disagreement is
# a finding to prove.
#
# The bug shape demonstrated here is real: flocker issue #118
# (https://github.com/jsocolar/flocker/issues/118), where a backward
# recursion for dynamic occupancy models applied a matrix product in the
# wrong order — (T %*% e) * beta instead of T %*% (e * beta) — producing
# wrong smoothed occupancy probabilities for every dynamic model with
# >= 3 seasons, while the package's own unit test stayed green because it
# used the one parameter family where the bug cancels exactly.
#
# Runs with base R only:  Rscript oracle.R

## ---- Model -----------------------------------------------------------------
# Dynamic occupancy: latent z_t in {0,1} per season t.
#   z_1 ~ Bernoulli(init)
#   z_t | z_{t-1}=0 ~ Bernoulli(colo[t])   (colonization)
#   z_t | z_{t-1}=1 ~ Bernoulli(1-ex[t])   (1 - extinction)
# Detection likelihoods per season, given the data:
#   el0[t] = P(observations in season t | z_t = 0)
#   el1[t] = P(observations in season t | z_t = 1)
# Target: smoothed marginal P(z_t = 1 | all observations), for every t.

## ---- Oracle: brute-force enumeration of all 2^n latent sequences -----------
brute <- function(el0, el1, init, colo, ex) {
  n <- length(el0)
  seqs <- as.matrix(expand.grid(rep(list(0:1), n)))
  joint <- apply(seqs, 1, function(z) {
    p <- ifelse(z[1] == 1, init, 1 - init) * ifelse(z[1] == 1, el1[1], el0[1])
    for (t in 2:n) {
      tr <- if (z[t - 1] == 0) { if (z[t] == 1) colo[t] else 1 - colo[t] }
            else               { if (z[t] == 0) ex[t]   else 1 - ex[t]   }
      p <- p * tr * ifelse(z[t] == 1, el1[t], el0[t])
    }
    p
  })
  post <- joint / sum(joint)
  sapply(seq_len(n), function(t) sum(post[seqs[, t] == 1]))
}

## ---- The clever way: forward-backward --------------------------------------
forward <- function(el0, el1, init, colo, ex) {
  n <- length(el0)
  f <- matrix(NA_real_, n, 2)
  f[1, ] <- c((1 - init) * el0[1], init * el1[1])
  for (t in 2:n) {
    Tm <- matrix(c(1 - colo[t], colo[t], ex[t], 1 - ex[t]), 2, byrow = TRUE)
    f[t, ] <- (f[t - 1, ] %*% Tm) * c(el0[t], el1[t])
  }
  f
}

backward <- function(el0, el1, colo, ex, buggy = FALSE) {
  n <- length(el0)
  b <- matrix(NA_real_, n, 2)
  b[n, ] <- c(1, 1)
  for (t in (n - 1):1) {
    Tm <- matrix(c(1 - colo[t + 1], colo[t + 1], ex[t + 1], 1 - ex[t + 1]), 2, byrow = TRUE)
    e  <- c(el0[t + 1], el1[t + 1])
    b[t, ] <- if (buggy) (Tm %*% e) * b[t + 1, ]   # the published bug shape
              else        Tm %*% (e * b[t + 1, ])  # correct
  }
  b
}

smoothed <- function(el0, el1, init, colo, ex, buggy = FALSE) {
  s <- forward(el0, el1, init, colo, ex) * backward(el0, el1, colo, ex, buggy)
  s[, 2] / rowSums(s)
}

## ---- 1. Generic parameters: oracle exposes the bug -------------------------
el0  <- c(0.1, 0.2, 0.3, 0.6)
el1  <- c(0.9, 0.8, 0.7, 0.2)
init <- 0.3
colo <- c(NA, 0.15, 0.40, 0.10)   # colo[t], ex[t] used from t = 2
ex   <- c(NA, 0.60, 0.05, 0.70)

oracle_ans  <- brute(el0, el1, init, colo, ex)
correct_ans <- smoothed(el0, el1, init, colo, ex, buggy = FALSE)
buggy_ans   <- smoothed(el0, el1, init, colo, ex, buggy = TRUE)

cat("Generic parameters (n = 4 seasons):\n")
print(round(data.frame(t = 1:4, oracle = oracle_ans,
                       correct_FB = correct_ans, buggy_FB = buggy_ans), 6))

stopifnot(max(abs(oracle_ans - correct_ans)) < 1e-12)  # correct FB == oracle
stopifnot(max(abs(oracle_ans - buggy_ans)) > 1e-3)     # bug is visible
cat("\n-> correct recursion matches the 2^4 enumeration exactly;",
    "\n-> buggy recursion is wrong at t <= n-2 (last two timesteps",
    "coincidentally right, which is why short tests miss it).\n\n")

## ---- 2. The parameter family where the bug cancels: a green that can't say no
# With ex = 1 - colo the chain is memoryless (both transition rows identical),
# the backward vector stays proportional to (1,1), and the buggy and correct
# recursions coincide EXACTLY. A unit test built in this family passes forever
# while the code is wrong for every other parameter set.
colo2 <- c(NA, 0.15, 0.40, 0.10)
ex2   <- 1 - colo2

cancel_correct <- smoothed(el0, el1, init, colo2, ex2, buggy = FALSE)
cancel_buggy   <- smoothed(el0, el1, init, colo2, ex2, buggy = TRUE)
cancel_oracle  <- brute(el0, el1, init, colo2, ex2)

stopifnot(max(abs(cancel_correct - cancel_buggy)) < 1e-12)
stopifnot(max(abs(cancel_correct - cancel_oracle)) < 1e-12)
cat("Cancelling family (ex = 1 - colo): buggy == correct to machine precision.\n")
cat("A test using these parameters is green with the bug present —\n")
cat("the test is a claim, not an oracle. The enumeration is the oracle.\n")
