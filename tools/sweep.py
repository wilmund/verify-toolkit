#!/usr/bin/env python3
"""Watchlist sweeper: track your filed PRs and issues across many repos.

Reads a plain-text watchlist (one item per line):

    owner/repo pr 123       # a pull request you filed
    owner/repo issue 456    # an issue you filed
    # comments and blank lines are ignored

Usage:
    GITHUB_TOKEN=... python3 sweep.py watchlist.txt

For every item it prints state, comment counts, and last-update time, so a
single run per work session shows where a maintainer has moved (respond
same-session) and where nothing has changed (stay silent).

For PRs it also reports CI status — including the two states GitHub renders
misleadingly, both learned from real incidents:

* A run can "complete: failure" with ZERO jobs executed (workflow-level
  startup failure, e.g. first-time-contributor approval gating or an
  account-level billing/quota problem). That red X looks like your code
  failed; nothing ran. Two maintainers have closed fine PRs on that pixel
  alone. This tool reports job-level conclusions so red-that-never-ran is
  distinguishable from red-that-failed.

* Approval-gated workflow runs create NO check-runs at all, and auto-expire
  to "failure" 30 days after creation. The check-runs API is blind to them;
  only the workflow-runs API (queried with the FULL head SHA — abbreviated
  SHAs silently return nothing) sees the state. This tool falls back to
  workflow runs and prints an EXPIRES-RED date for every pending gated run,
  so the flip arrives on a calendar instead of as an alarm.
"""
import json
import os
import sys
import urllib.request
from datetime import datetime, timedelta

TOK = os.environ.get("GITHUB_TOKEN")
H = {"Accept": "application/vnd.github+json", "User-Agent": "verify-toolkit-sweep"}
if TOK:
    H["Authorization"] = f"token {TOK}"


def get(url):
    req = urllib.request.Request(url, headers=H)
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def parse_watchlist(path):
    prs, issues = [], []
    with open(path) as f:
        for ln, line in enumerate(f, 1):
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            try:
                repo, kind, num = line.split()
                num = int(num)
            except ValueError:
                sys.exit(f"{path}:{ln}: expected 'owner/repo pr|issue N', got: {line}")
            (prs if kind == "pr" else issues).append((repo, num))
    return prs, issues


def ci_status(repo, head_sha):
    """Job-level CI summary for a commit, with the gated-run fallback."""
    cr = get(f"https://api.github.com/repos/{repo}/commits/{head_sha}/check-runs?per_page=50")
    runs = cr.get("check_runs", [])
    if runs:
        concl = {}
        for r in runs:
            c = r.get("conclusion") or r.get("status")
            concl[c] = concl.get(c, 0) + 1
        return ",".join(f"{k}:{v}" for k, v in sorted(concl.items()))

    # No check-runs: approval-gated workflows live only at the workflow-runs
    # level, and only with the full SHA.
    wr = get(f"https://api.github.com/repos/{repo}/actions/runs?head_sha={head_sha}&per_page=20")
    wruns = wr.get("workflow_runs", [])
    if not wruns:
        return "no-checks"
    concl, expiries = {}, []
    for r in wruns:
        c = r.get("conclusion") or r.get("status")
        concl[c] = concl.get(c, 0) + 1
        if c == "action_required":  # gated; flips red 30 days after creation
            created = datetime.strptime(r["created_at"], "%Y-%m-%dT%H:%M:%SZ")
            expiries.append((created + timedelta(days=30)).strftime("%m-%d %H:%M"))
    out = "wf:" + ",".join(f"{k}:{v}" for k, v in sorted(concl.items()))
    if expiries:
        out += " EXPIRES-RED:" + ",".join(sorted(set(expiries))) + "Z"
    return out


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__.strip().splitlines()[0] + "\nusage: sweep.py <watchlist.txt>")
    prs, issues = parse_watchlist(sys.argv[1])

    if prs:
        print("== PRs ==")
    for repo, n in prs:
        try:
            p = get(f"https://api.github.com/repos/{repo}/pulls/{n}")
            try:
                ci = ci_status(repo, p["head"]["sha"])
            except Exception as e:  # CI readout failing shouldn't hide the PR row
                ci = f"ci-err:{e}"
            merged = " MERGED" if p.get("merged") else ""
            print(f"{repo}#{n}: {p['state']}{merged} cmts={p['comments']} "
                  f"rev={p['review_comments']} upd={p['updated_at']} ci=[{ci}]")
        except Exception as e:
            print(f"{repo}#{n}: ERROR {e}")

    if issues:
        print("== Issues ==")
    for repo, n in issues:
        try:
            i = get(f"https://api.github.com/repos/{repo}/issues/{n}")
            print(f"{repo}#{n}: {i['state']} cmts={i['comments']} upd={i['updated_at']}")
        except Exception as e:
            print(f"{repo}#{n}: ERROR {e}")


if __name__ == "__main__":
    main()
