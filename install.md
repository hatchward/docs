# Installing hatchward

**Audience: whoever is putting hatchward on a machine.** For what you are agreeing
to, see [Licence terms](license.md).

Binaries are published on GitHub Releases for macOS (arm64, x86_64) and Linux
(x86_64, arm64) — the four targets every release builds. The runtime is
POSIX-only (signals, `setsid`, `flock`); Windows is not supported in v1.

Every route below verifies the tarball it installs against the `SHA256SUMS`
manifest published in the same release, which proves the two are
self-consistent, not where either came from.

## Before you start: an account and a project

A runner works projects that already exist in a Hatchward account, and it joins
with an enrollment code the console issues. Set those up first:

1. **Create an account** at [dash.hatchward.dev](https://dash.hatchward.dev).
   Enter your email; the console sends a single-use code that signs you in, or
   creates the account if there isn't one. There's no password.
2. **Choose a plan** under **Plan & billing**. Enrolling a runner needs an
   active plan.
3. **Connect your board and GitHub** under **Integrations**. Repository access
   goes through the GitHub App. See [Notion tickets](notion.md),
   [Mahfouz tickets](mahfouz.md) and [GitHub Projects](github-projects.md) for
   the ticket sources.
4. **Create and publish a project.** The setup wizard walks through *Board*,
   *Repositories*, *Map tickets*, *Agents & routing* and *Review & publish*.
   Nothing takes effect until it's published.
5. **Generate an enrollment code** from **Fleet** (or the project's page),
   choosing the projects this machine should work. Keep the page open: the
   code is single-use and expires, and the console shows the commands to copy.

Then install the CLI on the machine, below, and enroll it under
[First run](#first-run).

## Install

### One line, macOS and Linux

```sh
curl -fsSL https://hatchward.dev/install.sh | sh
```

It detects your platform, hands over to Homebrew if you are on macOS and have
it, and otherwise downloads the release, checks your tarball against
`SHA256SUMS`, and installs the binary.

Piping a script you have not read into a shell is a choice, not an obligation.
The same script, read first:

```sh
curl -fsSL https://hatchward.dev/install.sh -o install.sh
less install.sh && sh install.sh
```

It installs to `/usr/local/bin` when that is writable and `~/.local/bin`
otherwise, and never calls `sudo` on your behalf. Override with
`HATCHWARD_INSTALL_DIR=...`, pick a version with `HATCHWARD_VERSION=vX.Y.Z`, or
skip the Homebrew path with `HATCHWARD_NO_BREW=1`.

### macOS, with Homebrew directly

```sh
brew install hatchward/tap/hatchward
```

Then `brew upgrade hatchward/tap/hatchward` as usual.

**Use the fully qualified name.** Since Homebrew 6, formulae from third-party
taps must be trusted before they load, and Homebrew grants that automatically
only for a name written in full. `brew tap hatchward/tap` followed by
`brew install hatchward` is refused with *"Refusing to load formula … from
untrusted tap"* — as is the longer spelling `hatchward/homebrew-tap/hatchward`,
which resolves to the same tap but is not the canonical name. Both read like a
security problem and are really just the wrong name.

Installing that way also records the trust, so `brew doctor` stays quiet. If you
tapped without installing anything, it will instead report:

```
Warning: The following taps are not trusted:
  hatchward/tap
```

That is Homebrew noticing a tap it has been given no reason to trust, not a
problem with the tap. Installing clears it. So does trusting the tap outright,
which is the better option if you expect more than one formula from us later —
trust recorded by installing covers that formula alone:

```sh
brew trust hatchward/tap
```

**Do not turn the check off.** Homebrew suggests
`HOMEBREW_NO_REQUIRE_TAP_TRUST=1` in its own remediation text and, in the same
breath, that it is not recommended and is going away. It would also disable the
check for every tap on the machine, not just ours.

To remove it later: `brew uninstall hatchward`, then `brew untap hatchward/tap`
— the tap outlives the formula otherwise.

### Manually, from the tarball

For Linux hosts without Homebrew, air-gapped installs, or anywhere you want the
steps in front of you.

The tag and the filenames differ on purpose. The tap hosts formulae for more
than one tool, and its release tags are a shared namespace, so hatchward's
releases there are tagged `hatchward-v1.0.0`. The files inside keep the bare
version, because they are built and checksummed before anything knows where they
will be mirrored.

```sh
TAG=v1.0.0
BUILD=darwin_arm64          # or darwin_amd64, linux_amd64, linux_arm64
BASE=https://github.com/hatchward/homebrew-tap/releases/download/hatchward-$TAG

curl -fsSLO $BASE/hatchward_${TAG}_${BUILD}.tar.gz
curl -fsSLO $BASE/SHA256SUMS

sha256sum -c --ignore-missing SHA256SUMS
tar -xzf hatchward_${TAG}_${BUILD}.tar.gz
sudo install -m 0755 hatchward /usr/local/bin/hatchward
```

Releases are mirrored to `hatchward/homebrew-tap` so that these URLs, and the
formula, resolve without a GitHub account.

## The macOS quarantine trap

**Symptom: hatchward is killed the instant you run it, printing nothing.** No
dialog, no error, no output on stdout or stderr — just exit status 137. It reads
exactly like a corrupt download, and it is not one: the checksum and the
signature both verify.

```console
$ hatchward --version
$ echo $?
137
```

The cause is not the binary, it is an extended attribute on the file you
downloaded. A **browser** stamps `com.apple.quarantine` on the `.tar.gz` — as do
AirDrop, Mail and Slack. That attribute survives `tar -xzf` onto the extracted
binary and survives `install` to its final path, so clearing it after the fact on
the wrong file will not help. Gatekeeper then refuses the binary, and macOS kills
it with SIGKILL rather than explaining itself.

hatchward binaries carry the ad-hoc signature Go's linker applies, which is
enough for the kernel to execute an arm64 binary but not enough for Gatekeeper to
accept a quarantined one.

**None of the routes above are affected.** `curl` does not set the attribute, and
neither does Homebrew, so anything installed by following this page never hits
it. If you already fetched a tarball in a browser, clear the attribute **on the
tarball, before extracting**:

```sh
xattr -d com.apple.quarantine hatchward_${TAG}_${BUILD}.tar.gz
```

If you have already extracted and installed, clear it on the installed binary
instead:

```sh
xattr -d com.apple.quarantine "$(command -v hatchward)"
```

`xattr -l <file>` shows whether the attribute is present at all.

**Why the binaries are not notarized.** Apple issues the Developer ID certificate
that notarization requires only to paid Apple Developer Program members. Until
hatchward has one, downloads carry no Gatekeeper approval — which changes nothing
about the signature you can verify yourself, and nothing about a download made
with `curl` or `brew`.

## First run

**Docker must be installed and running first.** Every assignment executes in its own
container; the runner shells out to `docker` directly and has no other execution path.
The container image is part of the project's cloud configuration, never of the runner:
each assignment names the image it runs in. With contract 3, the workload has no direct
network, no capabilities and no real credentials. To let an image reach the model API and
push code, allow it in `~/.hatchward/runner.yml` and give the runner credential files:

```yaml
runtime:
  kind: container
  isolation: container
  ports: []
  agentImages:
    - ghcr.io/hatchward/agent:claude-v*      # exact reference, or a trailing "*"
  egressAllow:
    - internal.example.com                   # extra hostnames the image may reach; exact only
```

The agent images moved from `ghcr.io/influpert/agent` to `ghcr.io/hatchward/agent` in
v0.4.0. A runner whose `agentImages` still lists the old namespace will not trust the new
images: replace the entry (or add the new one) before upgrading.

```sh
install -m 0700 -d ~/.hatchward/secrets/_default
install -m 0600 /dev/null ~/.hatchward/secrets/_default/anthropic_api_key   # then paste the key into it
install -m 0600 /dev/null ~/.hatchward/secrets/_default/github_token        # optional; fine-grained, one repository
```

An image on the `agentImages` list can use an authenticated proxy. It never holds a real credential: the runner starts
a per-assignment, credential-injecting egress proxy in its own process, and the container
gets only the proxy's URL, the proxy's CA certificate, and sentinel credential values
(`hatchward-proxy-managed`). The proxy terminates TLS for the Anthropic and GitHub
hostnames, rewrites the sentinel into the real value read from
`~/.hatchward/secrets/<project-id>/` (falling back to `_default/` per file; recognised
names are `anthropic_api_key`, `claude_code_oauth_token` and `github_token`), and tunnels
every other allowlisted hostname opaquely, without terminating TLS on it. The allowlist
is the union of the runner's own base list (toolchain registries, GitHub, Anthropic) and
`runtime.egressAllow`, which accepts only exact lowercase hostnames — no wildcards, no
CIDR ranges, no IP literals, no port suffixes. A hostname not on the allowlist is refused
at the proxy, regardless of what the image's own firewall would otherwise permit. Every
directory on the credential path must be a real `0700` directory and every credential a
regular `0600`/`0400` file; dot-files and subdirectories are ignored, any other file name
is refused. Credential values never appear in the runner's arguments or environment, and
never in `runner.yml`. Contract-3 images must be listed in `agentImages` before they
can start: this is also the operator's approval to run the image's trusted filesystem
bootstrap. Review the image source and prefer immutable image digests. Older Linux
images outside the list retain their isolated execution with no proxy or network.
The portable image contract (version 3) is documented in
the image repository, `hatchward/agent`, under `docs/portable-runtime.md`.

**Do not list a contract-1 image in `agentImages` after upgrading the runner.** A runner
built with proxy-based credential injection cannot supply the credentials a contract-1
image expects. A contract-1 image expects its credentials
bind-mounted under `/run/secrets/`, which this runner no longer does — pointing
`agentImages` at a contract-1 image after upgrading does not fail loudly. Instead the
image finds no `/run/secrets/` mount and its entrypoint sets the sentinel string
(`hatchward-proxy-managed`) itself as a literal, bogus credential value, so the assignment
runs and fails against the real API rather than refusing to start. Upgrade the runner and
switch `agentImages` to a contract-3 image together; do not upgrade the runner binary
while still pinning a contract-1 image.

**The proxy's bearer token is available to the workload.** Its proxy URL includes an
assignment-specific token because the workload needs it to reach the proxy. That token
is scoped to one assignment's proxy listener and stops working
the moment the assignment's proxy closes. It is not a substitute for keeping
`~/.hatchward/secrets/` itself readable only by the runner's own user.

**macOS uses Docker Desktop and a contract-3 image.** The runner runs natively on the
Mac. Docker Desktop supplies Linux containers; no separately managed Linux runner is
needed. The runner inspects the selected image and rejects older contracts on macOS.
Contract-3 images also select this runtime on Linux. Windows support is not yet validated.

The container uses `--network none`. A bounded pool of Docker exec streams carries
proxy requests and assignment actions to the native runner, so neither Docker bridge
addresses nor host Unix socket mounts have to cross the Docker Desktop VM boundary.
Real credentials remain in the native runner process. The trusted image bootstrap mounts
storage before starting the workload, then drops every capability; all persistent image
processes run without capabilities.

**Storage requirements.** The Docker engine must expose `/dev/fuse` and permit the
contract-3 bootstrap's FUSE mount. A fixed-size ext4 filesystem in an assignment-owned
Docker volume enforces the disk ceiling. Workspace, home, temporary files, and runtime
files all share this ceiling, including filesystem metadata and the image's copied home
contents. Allow at least 1 GiB for the Claude image, plus room for the repository and its
build output. Insufficient space fails the assignment; it does not silently remove the
limit. Writable external mounts are refused; extra read-only mounts must target `/mnt/`.
The container and its backing volume are removed when the assignment ends or is canceled.

Linux images using older contracts keep the previous bridge-network runtime, which
requires a native Linux engine and storage-driver quota support. Use contract 3 for
the portable runtime and its explicit filesystem limit.

Clone the repository into the configured workspace before enabling the project. The
runner streams a snapshot into the bounded container filesystem without following host
symlinks; an empty workspace remains an image configuration error.

For a source checkout before contract-3 images are published:

1. Build the updated native runner from `src/cli` using the repository's pinned Go toolchain.
2. In the matching `hatchward/agent` checkout, build the base and Claude images using its
   documented contract-3 build commands. Check the label with
   `docker image inspect --format '{{index .Config.Labels "org.hatchward.agent.contract"}}' <image>`;
   it must print `3`.
3. Select that exact local image tag in the project's hosted agent configuration, and add
   the same tag to `runtime.agentImages` in `~/.hatchward/runner.yml`.
4. Configure the host credential files above, allocate the assignment's disk and memory
   ceilings, then enroll below. A local image must be present in the Docker context
   used by the runner.

With an enrollment code from the console (see
[Before you start](#before-you-start-an-account-and-a-project)):

```sh
hatchward enroll --name <runner-name>   # asks for the code and a workspace folder
hatchward service install               # runs it as a boot service from now on
# or, to run it in this terminal instead:
hatchward
```

**Enrolling turns on the code's projects.** `hatchward enroll` asks for the
one-time code, then for a folder to keep workspaces in (default
`<runner home>/workspaces`, created if missing), and enables every project the
code was issued for under the alias `workspaces`. `--path <dir>` names the
folder and skips that question. The folder is checked before the code is
redeemed. If the code is wrong, expired, or already used, enrollment fails with
the server's error and nothing is written; generate a fresh code and re-run.
If the projects can't be fetched, enrollment still succeeds and says how to
enable them by hand.

**Bare `hatchward` is the whole loop.** On an unenrolled machine it does the
same enrollment first, then runs; on an already-enrolled one it starts asking
the hosted control plane for work immediately. Scripted or unattended setups
pipe the code with `hatchward enroll --code-stdin` (without `--path`, the
default workspace folder is used) — a boot-service unit with no TTY on an
unenrolled machine fails fast with a named error rather than hanging on a
prompt.

**Adding or removing projects later.** `hatchward project enable` binds a
project to a local directory: `--project-slug <slug>` (asks the hosted API for
the id) or `--project-id <uuid>`, with `--workspace-root <alias> --path <dir>`.
`hatchward project list` shows each enabled project and, when one can't run on
this machine, why; `hatchward project disable` turns one off without
discarding the alias.

**`hatchward service install` keeps it running.** It registers the runner as a
boot-time service — a launchd agent on macOS, a systemd unit on Linux — so a
reboot or a crash resumes on its own, with no terminal or tmux session to keep
alive. Its output goes to `runner.log` in the runner's home
(`~/.hatchward/runner.log` by default). `hatchward service status` reports
install state and `hatchward service uninstall` removes it.

`hatchward doctor` and `hatchward config show/open` are not part of this
cutover; they land in a follow-up.

Releases at or before `v0.6.0` verified with a detached Hatchward release
signature over `SHA256SUMS` instead of checksums alone; the key and the steps
for those older releases are preserved at the `v0.6.0` tag, not on this page.
