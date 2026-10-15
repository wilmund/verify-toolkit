# Gates: check before you touch

Run these **in order, before cloning anything in anger**. Any failed gate means the package is a no-go — move to the next candidate. A failed gate discovered *after* a deep check wastes the check; a failed gate discovered after *filing* damages the relationship the whole practice depends on.

## 1. License

The repo has an open license. No license = the code is all-rights-reserved by default; you can read it, but a fix-carrying PR is legally murky and an issue is the most you should file (and say why).

## 2. CLA / DCO

Check `CONTRIBUTING.md`, the org's `.github` repo, and the PR template for a Contributor License Agreement. If you are an AI agent you cannot sign a legal agreement; if you are a human, decide whether you want to. A CLA-gated repo (any Google repo, for example) gets findings as an **issue the maintainer can apply themselves**, never a PR that will sit blocked forever.

## 3. AI-contribution policy — repo AND org level

If you are an agent, or using one heavily, this gate is absolute.

- Check the repo: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, issue/PR templates.
- **Check the maintaining organization's website.** Policies can live only there, invisible from the repo. A real case: a PR was closed under an org AI policy published solely on the org's own site — while the repo itself shipped AI-assistant configuration. The repo looked welcoming; the org had said no.
- Some orgs permit AI contributions **with disclosure** (e.g. rOpenSci's 2026 policy). Disclosure then isn't politeness, it's the terms of entry — state what you are in the first filing.

A policy against AI contributions ends the check, full stop. Respecting it is worth more than any fix you could offer. And if your PR is closed under such a policy: do **not** reply, do not file follow-up issues. Silence is the only compliant response; your findings remain in the closed PR for humans to use or not.

## 4. Maintainer reception — keep a blocked list

Maintain a `DO-NOT-CONTACT` file of projects where you've received a stop signal, and **check it by name before any outward contact**. Stop signals that belong on it:

- **Explicit**: "please don't file further reports." The maintainer's stated preference is the rule on their repo, permanently, even if your findings were technically correct.
- **Silent dismissal**: issues closed "not planned" without a word. The only right response is silence — record it, move on. Do not ask why.
- **Implicit**: your first report sits unanswered. An unanswered report is itself a signal (see `04-filing.md` — follow-ups gate on a *response*, never on time elapsed).

One stop signal — even an implicit one — makes the repo a no-go. This gate exists because reports cost maintainers real hand-checking time, and a maintainer who has said "this isn't helping" is right about their own project.

## 5. Activity

A dormant repo (months without commits or issue responses) can't receive a finding; filing into a void helps nobody and inflates your own numbers dishonestly. Check: last commit, last maintainer reply to an external issue, open-PR staleness.

## 6. In-flight rework

Before investing in a deep check — and again before filing — look for major in-progress branches or rewrite PRs. Two reasons:

- Your finding may already be fixed there (don't file churn against the maintainer's own work).
- Better: **diff the rework before filing** and tell the maintainer exactly which findings survive their own rewrite. "Here's what your v2 still needs" is worth far more than "here are bugs." In one real case, 2 of 6 verified bugs persisted verbatim in the maintainer's in-flight rewrite — saying so precisely is what got all of them fixed in the next release.

## Output of this stage

A go/no-go decision, and if go: the clone's commit SHA recorded, the org policy status noted (especially any disclosure requirement), and the PR-vs-issue ceiling already known (CLA → issues only).
