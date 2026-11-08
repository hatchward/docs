{% raw %}
<h2 id="v0.9.0">0.9.0</h2>

**First signed and notarized macOS build, and the first release cut automatically on
merge to `main`.** The CLI's behaviour is unchanged since 0.8.0. 0.8.0 never reached the
Homebrew tap, so Homebrew users move from 0.7.0 straight to 0.9.0.

### Changed

- macOS binaries are codesigned and notarized; a release fails rather than ship them
  unsigned.
- A merge to `main` that adds a new `.github/releases/v<semver>.md` tags and publishes the
  release (`release-on-main.yml`).
- Hosted configuration owned by Hatchward is prefixed `HATCHWARD_`, and the API Worker's
  runtime secrets sync from Bitwarden on deploy.

<h2 id="v0.8.0">0.8.0</h2>

**First release from `hatchward/core`.** The repository moved from `influpert/hatchward`
and the tap from `influpert/homebrew-tap` to `hatchward/homebrew-tap`; old URLs redirect.
The CLI's behaviour is unchanged since 0.7.0.

### Changed

- Dependencies: `modernc.org/sqlite` 1.61.1, `golang.org/x/sys` 0.49.0,
  `golang.org/x/term` 0.47.0.
- Task contracts accept optional `waitingReason` and `attentionReason` fields, which the
  CLI does not use yet.
- `bin/release` and `release.yml` target `hatchward/core` and `hatchward/homebrew-tap`.

<h2 id="v0.7.0">0.7.0</h2>

**Hard cutover to the hosted runner.** Bare `hatchward` is now the whole operator loop:
enroll this machine to a hosted project with a one-time code, then run it. The
self-hosted product — the local `init` wizard, offline licensing, the embedded
control-plane server, leader election, and the local scheduler — is gone; see Removed
below. This entry covers the whole cutover, landed as a stacked series of PRs on
`cutover/hosted-cli`; the tag lands once the series merges to `main`.

### Removed

- **The `hatchward init` wizard and its terminal frame** (`internal/tui`). Nothing in the
  surviving CLI writes `node.yml`/`config.yml`; a project is selected with
  `hatchward project enable`.
- **HW1 offline licensing** — Roughtime/signed-time floors, key ceremonies, and the
  `hatchward-sign`/`hatchward-timed` binaries. The CLI carries no license gate and no
  license state; a hosted project's entitlement lives in the control plane, not on the
  runner's disk.
- **The embedded control-plane server** (`hatchward controlplane serve`), leader
  election, the three `CoordinatorDriver` coordination modes, and the local
  scheduler/worker/ledger/audit stack that backed them. Coordination is the hosted
  control plane's job now.
- **`hatchward doctor` and `hatchward config`.** Hosted-runner equivalents are a
  follow-up; `hatchward` reports enrollment and project state on its own output today.
- **Every board/registry/logging driver** (GitHub, Notion, Slack, the local mock and
  file drivers) and the `hatchward agent`/`board`/`ask`/`page`/`release`/`fleet`/
  `dashboard`/`status`/`drain`/`pause`/`resume`/`logs`/`ledger`/`notify` command
  families that used them.
- **The Hatchward release signature, detached-key verification, and the
  control-plane Docker image.** All of `etc/keys/` (license, time, roughtime, and
  release anchors), `hatchward-sign`, `bin/verify-release-key`, the `Dockerfile`,
  and the `image` job in `release.yml` are gone. Releases are checksum-only now
  (`SHA256SUMS`, verified with `sha256sum -c`); Homebrew, Apple codesign/notarize,
  and Windows Authenticode are unaffected. This is a security regression on the
  Linux `curl | sh` path. `SHA256SUMS` is fetched
  from the same GitHub release as the tarball, so the checksum proves the two are
  self-consistent, not who produced either — `hatchward.dev`'s DNS is now the sole
  trust boundary for that install path (see
  architecture.md). Replacing this with
  `actions/attest-build-provenance` is a separate follow-up, not part of this PR.

### Changed

- **The `runner` command group is gone.** `runner run` is now the root: bare
  `hatchward` runs an enrolled machine, or joins one that isn't enrolled yet.
  `runner service` is now the top-level `service` group
  (`install`/`status`/`uninstall`); the installed boot-service unit invokes
  `hatchward --config <runner.yml>` directly.
- **`hatchward project enable` gained `--path <dir>`**, so a project can be enabled
  without hand-editing `runner.yml` first.

<h2 id="v0.6.0">0.6.0 (2026-08-17)</h2>

### Added
- `hatchward dashboard` — an interactive terminal view of the whole fleet: a persistent
  node list plus a reactive detail pane (live worker table + log tail locally, a
  read-only heartbeat mirror for a remote node)
- `hatchward fleet start/stop/status/install/uninstall` — run `hatchward run` in the
  background and install it as a boot service (launchd/systemd `--user`) that survives a
  reboot and restarts on crash
- `agent.role_agents` — a fleet role can resolve to an external agent invoked by name,
  not just a local `<role>.md` playbook file

### Changed
- `notify.driver`/`notify.target` moved from `node.yml` to `config.yml` — hard cutover,
  no back-compat shim
- Slack alerting and the local audit log unified into one `LogDriver` mechanism and one
  `config.yml` `logging:` list; `notify:` is gone in favor of `logging:` — hard cutover

### Fixed
- `hatchward init` refuses to write `config.yml` when a routed agent has no matching
  role file, instead of failing at `hatchward run` time
- The `init` wizard no longer asks for `agent.repo`/`agent.base_branch` under isolation
  modes that never use them
- `hatchward drain` and `registry list`/`upsert` no longer fail under leaderless
  coordination by opening `registry.fleet` unconditionally; drain no longer wipes
  `Role` or reports an empty build version

<h2 id="v0.5.1">0.5.1 (2026-08-17)</h2>

### Fixed
- `status`, `pause`, `drain`, `board`, `release`, `logs`, `notify`, `page`, `registry`,
  and `resume` now load `.env` before running; a secret written only to `~/.env` was
  previously invisible to all ten
- `agent.roles_dir` can now point outside the project checkout, via an absolute or
  `~`-prefixed path, matching `repo.path`'s existing override support
- Seven ordering and coverage gaps in the `hatchward init` wizard, including a new
  **Agent fleet** stage for isolation mode, capacity limits, and `roles_dir`

<h2 id="v0.5.0">0.5.0 (2026-08-16)</h2>

### Added
- A control plane started automatically by `hatchward init`, with `controlplane
  start/stop/status` verbs and `cp install` to survive a reboot (launchd on macOS,
  systemd `--user` on Linux), plus a Homebrew service block
- `hatchward ask` — a worker can park a task on a question for a human instead of
  guessing or burning an attempt; the answer is delivered automatically on the worker's
  next spawn, authenticated by a per-spawn token and fenced before it reaches the agent
- Board comment reading (`CommentReader`) across all four board drivers, and a `doctor`
  probe that verifies the token can actually read a reply, not just post a question
- A `github` board driver (GitHub Projects v2) and a release log over GitHub Releases

### Fixed
- Starter pipeline routing ignored the operator's actual status field name, silently
  matching no ticket on a board with a differently named column
- Attempt-capping and claim renewal were silent no-ops for every host-isolated worker
- A Notion-backed fleet instance dropped out of liveness after roughly eight finished
  worker runs; property and comment writes over Notion's per-run and per-page read
  limits are now bounded or refused instead of silently truncated on the next read
- `init`'s setup preamble and next-steps text assumed Notion and Slack regardless of the
  driver actually chosen
- `hatchward-timed` now refuses to start on a signing-key/id mismatch instead of
  silently mislabeling every response it signs
- Three licence-enforcement bugs: unbounded `issued_at`/`expires_at` could wrap
  `Remaining()` positive past ~292 years out, installing a new licence falsely reported
  the state file as tampered, and `license install` didn't warn when a
  higher-precedence environment variable would silently override it
- Pasting, escape sequences, and long values in the `init` setup frame — see Security
  below, several of these are also security fixes

### Security
- A forward-dated licence could permanently brick a machine's trust state, expiring
  every other licence on it with no recovery short of hand-deleting state files
- A key meant only for the always-online time server could be reused as the offline
  entitlement-signing key; keys are now rejected if the same material appears under two
  kinds
- A signing key can now be capped in what it's allowed to grant — mechanism only, no
  issued key uses it yet
- Signed-time verification could not run at all in any released binary through
  v0.3.1 — no time keys were ever embedded; CI now hard-fails a build with an empty
  anchor set
- A pasted credential could be written to `.resume/init-*.json` in plaintext and kept
  for 14 days, via a control-byte paste bug; a related bug let stray type-ahead leak
  onto a visible prompt
- The control-plane server was hardened ahead of being made default-on: request
  timeouts, a 64 KiB body cap, no error detail on the unauthenticated health route, and
  its database files narrowed to the owner
- Board comments are fenced (`internal/untrusted.Fence`) before reaching a worker's
  prompt, and the question a reply answers is authenticated by a per-spawn token rather
  than merely pattern-matched

### Changed
- A cleartext `base_url` is now refused and blocks startup. **May require action:** an
  existing driver pointed at a cleartext internal host or proxy will fail `doctor`
  fatally on its next restart
- Secret prompts show a fixed-width masked preview instead of nothing, so a silent
  paste failure is visible
- `controlplane serve` no longer needs an environment variable when a per-project token
  row exists

<h2 id="v0.3.1">0.3.1 (2026-08-11)</h2>

### Fixed
- The release workflow's `distribute` (Homebrew tap) and `image` (container) jobs were
  silently **skipped**, not failed, on every release once any earlier job in the chain
  skipped — GitHub Actions propagates a skip through an implicit `success()` check that
  a plain `if:` boolean doesn't suppress. `ghcr.io/influpert/hatchward:latest` had been
  stuck on v0.1.1 since v0.2.0, and the Homebrew tap had never received a formula at all
- The release workflow resolved secrets by project id, so `HOMEBREW_TAP_TOKEN` — filed
  in a different Bitwarden project than the one queried — was invisible and treated as
  unset; `distribute` quietly skipped with a green build. Secrets are now resolved by
  name across every project the CI token can read, and the tap token is now required
  rather than optional
- `init`: the pre-write review table could list secrets that the write would then
  silently drop; abandoned `.resume` answer files could survive a refused run; the
  resume sweep could be tricked into following a symlinked `.resume` and deleting
  through it; a connection probe's "already tested" state didn't invalidate when the
  operator went back and changed the answer it tested

### Security
- `bin/brew-formula` interpolated the release tag into a `sed` expression unescaped; a
  crafted tag could rewrite the generated formula's download host and pin an
  attacker-chosen checksum. Tag names are now allow-listed

<h2 id="v0.3.0">0.3.0 (2026-08-10)</h2>

### Added
- `hatchward init`'s setup wizard gained navigation: `back` to the previous or current
  stage, and a review hub that can jump directly to any stage and walks its dependents
  forward
- `init` can now resume an interrupted run from saved answers; credentials are
  deliberately never persisted to the resume file
- `init` now renders in a full-screen terminal frame (bubbletea v2) instead of
  scrolling line-by-line prompts
- A Homebrew tap (`influpert/tap`) plus a verified `install.sh` one-liner that
  checksum- and signature-verifies the download — works around macOS Gatekeeper
  silently killing browser-downloaded tarballs

### Fixed
- The `local` board/registry driver could create the instance home, lock files, and
  `state/` directories on disk before the operator confirmed the wizard's final write
  step, contradicting init's "nothing is written until you confirm" guarantee
- Error `EPOL003`'s published remediation text pointed at an internal-only doc; now
  points at the public `docs/multi-instance.md`

<h2 id="v0.2.0">0.2.0 (2026-08-08)</h2>

103 commits since v0.1.1; grouped by theme below.

### Added
- Content-publishing surface: `hatchward page create`/`page append` to publish
  Markdown as native Notion pages, `release create`/`release sync` for a release log
  (imports GitHub Releases), and generic `board next`/`board search` query verbs
- License-key enforcement, checked against a cryptographically verified time floor
  (Roughtime primary, HTTPS signed-time fallback) rather than the machine clock, so
  winding the clock back cannot extend a license
- Structured, stable error codes on every user-facing error, with generated reference
  docs (`docs/errors.md`)
- `hatchward init` interactive setup wizard, replacing hand-typed placeholder YAML with
  an eight-stage guided flow that reads menu options back from the board itself where
  possible
- `local` board and registry driver — a Markdown-file-backed board and fleet registry
  for running hatchward without a Notion workspace
- Board config reworked: split by owner into `node.yml` (per-machine) and `config.yml`
  (project, including the whole board); `board:` gained `filters`, an ordered
  `pipeline` replacing an implicit status column, a `started` verb, and
  `cache_ttl_seconds`
- Project docs published as the public hatchward.dev site

### Changed
- License changed from MIT to a proprietary license naming Influpert LLC as licensor,
  ahead of shipping license-key enforcement
- License and release signing key ceremonies run for real; released binaries now embed
  genuine trust anchors instead of empty placeholder directories

<h2 id="v0.1.1">0.1.1 (2026-07-26)</h2>

### Fixed
- Running `hatchward init` with no arguments printed cobra's generic
  `accepts 1 arg(s), received 0`; now names the missing argument and shows an example
- A brand-new `hatchward init` always failed with "doctor reported a fatal failure",
  because the freshly scaffolded template's placeholder values trip doctor's checks by
  design — init now recognizes that expected setup-pending state and succeeds with a
  "next steps" guidance block instead of exiting non-zero

<h2 id="v0.1.0">0.1.0 (2026-07-26)</h2>

First tagged release. Hatchward is a multi-instance agent-fleet orchestrator: it runs a
fleet of AI coding agents against a shared kanban board, vendor-neutral by construction,
with no long-running "manager LLM" — orchestration is a deterministic Go scheduler.

### Added
- Core orchestrator: deterministic scheduler (`hatchward run`), board-driven task
  assignment, and two pluggable coordination modes — leaderless via an embedded-DB
  control plane enforcing single assignment by compare-and-swap, and leaderful via
  best-effort bully election over the registry driver
- `hatchward agent` fleet command group (`start stop list logs watch shell prune doctor
  config provision run`), the Go port of the project's original bash worker-spawning
  tooling
- Operator CLI: `init`, `doctor`, `status`, `board`, `ledger`, `notify`,
  `pause`/`resume`, `drain`, `logs`
- Notion driver (board + registry), Slack driver (notify), and a local driver (logging)
- Safety rails: fleet-wide pause/resume kill switch, per-task attempt caps, per-role
  spawn cooldowns, orphan-assignment reclamation, and a full structured audit trail
- Platform support: macOS (arm64/x86_64) and Linux (x86_64); POSIX-only runtime,
  Windows unsupported
{% endraw %}
