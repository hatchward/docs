#!/bin/sh
# hatchward installer — https://hatchward.dev/install.sh
#
#   curl -fsSL https://hatchward.dev/install.sh | sh
#
# On macOS with Homebrew this hands over to `brew install`. Everywhere else it
# downloads the release, verifies its checksum, and installs the binary.
#
# Why this exists rather than just documenting curl+tar: a tarball fetched in a
# browser arrives carrying com.apple.quarantine, which survives extraction and
# `install`, and macOS then kills the binary with SIGKILL and prints nothing at
# all. curl does not set that attribute, so every route through this script is
# immune to it. See https://hatchward.dev/install.html, "The macOS quarantine trap".
#
# Read before running, if you like — that is why the inspect-first form is
# documented next to the pipe:
#
#   curl -fsSL https://hatchward.dev/install.sh -o install.sh
#   less install.sh && sh install.sh
#
# Environment:
#   HATCHWARD_VERSION       tag to install (default: the latest release)
#   HATCHWARD_INSTALL_DIR   where to put the binary (default: see pick_install_dir)
#   HATCHWARD_NO_BREW       set to any value to skip the Homebrew path on macOS

set -eu

TAP_REPO="hatchward/homebrew-tap"
RELEASES="https://github.com/${TAP_REPO}/releases"

# A tap is a repository of formulae, plural — it can carry other software, and
# its release tags are a single namespace shared by all of them. So hatchward's
# releases there are tagged `hatchward-v1.2.3`, not `v1.2.3`, which would claim
# the whole namespace for one formula and collide the moment a second is added.
#
# Only the *tag* is prefixed. Asset filenames keep the bare version
# (hatchward_v1.2.3_darwin_arm64.tar.gz) because they are built upstream, before
# anything knows where they will be mirrored, and SHA256SUMS names them.
#
# HATCHWARD_VERSION stays bare — users pin `v1.2.3`, not the mirror's tag.
TAP_TAG_PREFIX="hatchward-"

say()  { printf '%s\n' "$*"; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

need() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required but was not found on PATH."
}

# ---------------------------------------------------------------- platform ---

detect_target() {
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Darwin) os=darwin ;;
    Linux)  os=linux ;;
    *)      die "unsupported operating system: $os. hatchward ships for macOS and Linux; Windows is not supported in v1." ;;
  esac

  case "$arch" in
    x86_64 | amd64)  arch=amd64 ;;
    arm64 | aarch64) arch=arm64 ;;
    *)               die "unsupported architecture: $arch. hatchward ships for x86_64 and arm64." ;;
  esac

  printf '%s_%s' "$os" "$arch"
}

# ------------------------------------------------------------------- brew ---

# Homebrew is preferred on macOS because it handles upgrades and uninstalls, and
# because a formula install is never quarantined either. Only the fully
# qualified name is used: since Homebrew 6, HOMEBREW_REQUIRE_TAP_TRUST defaults
# to on and auto-trust fires only for a name with exactly two slashes, so
# `brew tap` followed by a bare `brew install hatchward` is refused.
#
# Every failure below returns 1 rather than exiting, so main() falls through to
# install_tarball. Homebrew being broken, or the tap being unreachable, is not a
# reason for this script to leave the machine with no hatchward on it.
#
# Note `set -e` does NOT protect this function: it is called as `if try_brew`,
# and errexit is suspended for the whole body of a function used as a condition.
# That is not a detail to work around — it is why every command whose failure
# matters is checked explicitly here. This used to run `brew install` and then
# print "Installed with Homebrew" unconditionally, so a failed install reported
# success and suppressed the fallback in the same breath.
try_brew() {
  [ "$(uname -s)" = "Darwin" ] || return 1
  [ -z "${HATCHWARD_NO_BREW:-}" ] || return 1
  command -v brew >/dev/null 2>&1 || return 1

  say "Homebrew detected — installing with brew."
  say ""
  say "  brew install hatchward/tap/hatchward"
  say ""
  if ! brew install hatchward/tap/hatchward; then
    say ""
    say "brew install failed — falling back to the signed tarball."
    return 1
  fi

  # brew exiting 0 is not proof there is a working binary: a formula can install
  # nothing, and a stale tap clone resolves an old formula. Ask brew where it put
  # the binary rather than trusting PATH, which need not contain the brew prefix
  # in the shell this script is piped into.
  brew_prefix="$(brew --prefix 2>/dev/null)" || brew_prefix=""
  if [ -z "$brew_prefix" ]; then
    say ""
    say "brew install reported success but \`brew --prefix\` does not answer, so"
    say "there is no way to check what it installed — falling back to the signed"
    say "tarball."
    return 1
  fi
  brew_bin="${brew_prefix}/bin/hatchward"
  if [ ! -x "$brew_bin" ]; then
    say ""
    say "brew reported success but no runnable hatchward is at $brew_bin —"
    say "falling back to the signed tarball."
    return 1
  fi

  installed="$("$brew_bin" --version 2>/dev/null)" || {
    say ""
    say "hatchward is installed at $brew_bin but does not run — falling back"
    say "to the signed tarball."
    return 1
  }

  say ""
  say "Installed $installed"
  # Being installed and being reachable are different claims, and only the first
  # was just verified. Say so rather than implying both.
  if ! command -v hatchward >/dev/null 2>&1; then
    say ""
    say "NOTE: $(dirname "$brew_bin") is not on your PATH in this shell."
    say "Open a new terminal, or add it, before running hatchward."
  fi
  say ""
  say "Upgrade later with:"
  say "  brew upgrade hatchward/tap/hatchward"
  return 0
}

# ---------------------------------------------------------------- verify ----

# Checksum only: the release signature was retired, so this proves the
# tarball matches the manifest served alongside it — not who produced either.
# See .claude/instructions/architecture.md's supply-chain section for the full
# security note.
verify_download() {
  dir="$1"
  tarball="$2"

  # --ignore-missing so the manifest can list all four targets while only one
  # was downloaded. Both spellings exist in the wild; older macOS has neither
  # sha256sum nor a shasum that understands the flag, hence the grep fallback.
  if command -v sha256sum >/dev/null 2>&1; then
    ( cd "$dir" && grep " ${tarball}\$" SHA256SUMS | sha256sum -c - >/dev/null ) \
      || die "checksum mismatch on ${tarball} — refusing to install."
  else
    ( cd "$dir" && grep " ${tarball}\$" SHA256SUMS | shasum -a 256 -c - >/dev/null ) \
      || die "checksum mismatch on ${tarball} — refusing to install."
  fi
  say "Checksum verified: ${tarball}"
  say "(This proves the download matches SHA256SUMS, not who published it —"
  say "hatchward.dev's DNS is the trust boundary for this install.)"
}

# ---------------------------------------------------------------- install ---

# /usr/local/bin if we can write it, otherwise ~/.local/bin. Deliberately no
# sudo: a script piped from the network should not be the thing that asks for
# your password. If /usr/local/bin is what you want, pass it explicitly and run
# the script under sudo yourself.
pick_install_dir() {
  if [ -n "${HATCHWARD_INSTALL_DIR:-}" ]; then
    printf '%s' "$HATCHWARD_INSTALL_DIR"
  elif [ -w /usr/local/bin ] 2>/dev/null; then
    printf '%s' /usr/local/bin
  else
    printf '%s' "$HOME/.local/bin"
  fi
}

# Yields the bare version tag (v1.2.3), never the mirror's namespaced one. The
# prefix is re-applied at the single place that builds a URL, so there is one
# spelling of the version in flight rather than two that can drift.
resolve_version() {
  if [ -n "${HATCHWARD_VERSION:-}" ]; then
    # Tolerate someone pasting the tag they saw on the tap's releases page.
    printf '%s' "${HATCHWARD_VERSION#"$TAP_TAG_PREFIX"}"
    return 0
  fi
  # NOT /releases/latest. That is a property of the repository, not of a
  # formula, and this repository is a tap — the most recent release in it may
  # belong to some other tool entirely, in which case /releases/latest resolves
  # to a tag that has no hatchward tarballs under it. The namespaced tags make
  # that detectable; they do not make it not happen.
  #
  # The atom feed lists releases newest-first, is public, needs no token and no
  # API quota, so the first `hatchward-` tag in it is this formula's latest
  # release regardless of what else the tap has published since.
  feed="$(curl -fsSL "${RELEASES}.atom" 2>/dev/null || true)"
  [ -n "$feed" ] || die "could not reach ${RELEASES}.atom to determine the latest hatchward version.
Set HATCHWARD_VERSION=vX.Y.Z to install a specific one."

  # Anchored on the href= attribute, not merely on /releases/tag/. Release
  # bodies appear in this feed, and a body is attacker-controlled by whoever can
  # publish ANY release in the tap — text like "see releases/tag/hatchward-v0.0.1"
  # in some other formula's notes would otherwise be picked up first and silently
  # downgrade every install. Atom escapes markup inside content, so `href="` only
  # survives unescaped in real link elements.
  tag="$(printf '%s' "$feed" \
    | grep -oE "href=\"[^\"]*/releases/tag/${TAP_TAG_PREFIX}[A-Za-z0-9._+-]+\"" \
    | head -n 1)"
  tag="${tag%\"}"
  tag="${tag##*/}"

  # The feed is a window on recent releases, not the full history. An empty
  # result means either no hatchward release exists or it has been pushed off
  # the end by other formulae — say so, rather than reporting "unreachable".
  [ -n "$tag" ] || die "found no ${TAP_TAG_PREFIX}* release in the most recent entries of ${RELEASES}.
Set HATCHWARD_VERSION=vX.Y.Z to install a specific one."

  printf '%s' "${tag#"$TAP_TAG_PREFIX"}"
}

install_tarball() {
  need curl
  need tar

  target="$(detect_target)"
  tag="$(resolve_version)"
  tarball="hatchward_${tag}_${target}.tar.gz"
  # Prefixed here and only here: the tag names the mirror's release, the
  # filename names the artefact built upstream. They are not the same string.
  base="${RELEASES}/download/${TAP_TAG_PREFIX}${tag}"

  say "Installing hatchward ${tag} (${target})."

  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064
  # Expanded now on purpose: $tmp must be captured while it is still in scope.
  trap "rm -rf '$tmp'" EXIT INT TERM

  for f in "$tarball" SHA256SUMS; do
    curl -fsSL -o "$tmp/$f" "${base}/${f}" \
      || die "could not download ${base}/${f}
If this is a brand-new release the assets may still be uploading; try again in a
minute, or pin a known version with HATCHWARD_VERSION."
  done

  verify_download "$tmp" "$tarball"

  tar -xzf "$tmp/$tarball" -C "$tmp"
  [ -f "$tmp/hatchward" ] || die "the archive did not contain a hatchward binary."

  dir="$(pick_install_dir)"
  mkdir -p "$dir" || die "could not create $dir"
  install -m 0755 "$tmp/hatchward" "$dir/hatchward" \
    || die "could not write to $dir. Set HATCHWARD_INSTALL_DIR to somewhere writable."

  say ""
  say "Installed $dir/hatchward"

  case ":${PATH}:" in
    *":${dir}:"*) ;;
    *)
      say ""
      say "$dir is not on your PATH. Add it:"
      say "  echo 'export PATH=\"$dir:\$PATH\"' >> ~/.zshrc"
      ;;
  esac
}

# -------------------------------------------------------------------- main ---

main() {
  if try_brew; then
    :
  else
    install_tarball
  fi

  say ""
  say "Next: hatchward   (it asks for your enrollment code, then runs)"
  say "Docs: https://hatchward.dev"
}

main "$@"
