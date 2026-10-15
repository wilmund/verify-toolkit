# Probe containers: pinned, boring, reusable

Every audit runs in its own container, built once, kept **stopped-but-reusable**. The pin is not bureaucracy — it is what makes your replication block (see `templates/replication-block.md`) possible, and it means a maintainer's follow-up question three weeks later gets answered against the *identical* environment.

Record at build time, because you will cite all of it later:

- container image (exact tag),
- the audited clone's commit SHA,
- versions of the key packages in the environment (`sessionInfo()` / `pip freeze` for the ones you'll name).

## R packages — `rocker/r2u`

r2u serves CRAN packages as Ubuntu apt binaries: dependency resolution that takes an hour from source takes seconds. This is the single biggest cost reducer for R audits.

```sh
# one container per audited package, named, reusable
docker run -d --name mypkg-probe -v /path/to/clone:/repo:ro rocker/r2u:24.04 sleep infinity

docker exec mypkg-probe sh -c '
  # install CRAN deps as apt binaries (seconds, not hours)
  Rscript -e "install.packages(c(\"depA\", \"depB\"))"
  # the repo is mounted read-only; builds write to the tree — copy first
  cp -r /repo /build
  R CMD INSTALL /build
'
docker exec mypkg-probe Rscript /probes/probe1.R   # mount or docker cp your probe scripts
docker stop mypkg-probe                             # keep it; restart for follow-ups
```

Gotchas that cost real time:

- **Read-only mounts break installs.** `R CMD INSTALL` and `pip install` both write into the source tree. Always `cp -r` inside the container first; keep the host mount `:ro` so a probe can never mutate the evidence.
- Packages needing compilation beyond CRAN binaries (Stan, for instance) still work — `install.packages()` falls back to source — but budget the time, and prefer probing post-processing layers that don't require a fresh model fit (packages often ship a pre-fit example object; use it).

## Python packages — `python:3.X-slim`

```sh
docker run -d --name mypkg-probe -v /path/to/clone:/repo:ro python:3.12-slim sleep infinity
docker exec mypkg-probe sh -c 'cp -r /repo /build && pip install /build'
docker exec mypkg-probe python /probes/probe1.py
docker stop mypkg-probe
```

Gotchas:

- Match the Python version to what the package's CI tests against — a probe failure on an unsupported Python is your finding, not theirs.
- When the package wraps system libraries (GDAL, ffmpeg, exiftool), apt-install them *and pin what matters*: e.g. a system-GDAL build can require holding `numpy` at a specific major version; record that pin or your replication block won't replicate.
- For uv/poetry-locked projects, audit the *exact lock*: `uv export --frozen --no-hashes -o reqs.txt`, then install from that — the maintainer's pins are part of the system under test.

## Why one container per package, kept around

- **Follow-ups are cheap.** Maintainer asks "does it also happen when X?" — `docker start`, run, answer, stop. Same versions, zero setup.
- **Disk is the price.** Probe containers accumulate (a practice of this size carries 15+). Watch disk; prune *dead build cache* (`docker builder prune`) and retired stacks before touching stopped probe containers, and drop a probe container only when its audit's upstream conversation has fully resolved.

## The one rule

**Never file from reading code.** Static reading finds candidates; only runtime finds facts. The measured gap from one real audit: 54 statically-flagged documentation mismatches reduced to **3** real ones at runtime (see `02-probes.md` for why). Everything in this file exists so that running the real thing is cheap enough that you never feel tempted to skip it.
