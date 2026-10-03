#!/usr/bin/env bash
#
# Laxtic Studios dependency setup for macOS and Linux.
#
# Laxtic Studios does its transcoding, its exports and every frame it reads
# through ffmpeg, on your machine. ffmpeg is NOT bundled with the app: shipping
# it would add a couple of hundred megabytes to every download, and it would be
# our build of it rather than the one your system trusts and updates. So the app
# looks for the one you already have, and this script is here to make sure you
# have one.
#
# It looks in the same order the app does:
#
#     $FFMPEG_PATH  ->  $PATH  ->  /opt/homebrew/bin  ->  /usr/local/bin  ->  /usr/bin
#
# If ffmpeg and ffprobe are already there, this script changes nothing and says
# so. If they are not, it shows you the exact command it wants to run, asks, and
# runs it only if you agree. Nothing is installed behind your back, and nothing
# is downloaded from anywhere but your system's own package manager.
#
#   ./setup.sh           check, and offer to install what is missing
#   ./setup.sh --check   check only, install nothing (exit 1 if something is missing)
#   ./setup.sh --yes     install what is missing without asking
#
set -euo pipefail

ASSUME_YES=0
CHECK_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --yes|-y)   ASSUME_YES=1 ;;
    --check|-c) CHECK_ONLY=1 ;;
    --help|-h)
      sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      printf 'setup.sh: unknown option %s (try --help)\n' "$arg" >&2
      exit 2 ;;
  esac
done

# ---------------------------------------------------------------- appearance
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  BOLD=$(printf '\033[1m'); DIM=$(printf '\033[2m'); RED=$(printf '\033[31m')
  GREEN=$(printf '\033[32m'); YELLOW=$(printf '\033[33m'); RESET=$(printf '\033[0m')
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; RESET=""
fi
ok()    { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$1"; }
bad()   { printf '  %s✗%s %s\n' "$RED" "$RESET" "$1"; }
note()  { printf '  %s%s%s\n' "$DIM" "$1" "$RESET"; }
warn()  { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$1"; }
head_() { printf '\n%s%s%s\n' "$BOLD" "$1" "$RESET"; }

# ------------------------------------------------------------------ discovery
# The app's own search order, reproduced exactly, so that what this script
# reports is what the app will find. `command -v` alone would miss the two
# Homebrew prefixes when a .app is launched from Finder, because a GUI process
# does not inherit your shell's PATH.
SEARCH_DIRS="/opt/homebrew/bin /usr/local/bin /usr/bin /bin /snap/bin"

find_tool() {
  tool="$1"
  env_override=""
  case "$tool" in
    ffmpeg)  env_override="${FFMPEG_PATH:-}" ;;
    ffprobe) env_override="${FFPROBE_PATH:-}" ;;
  esac
  if [ -n "$env_override" ] && [ -x "$env_override" ]; then
    printf '%s' "$env_override"; return 0
  fi
  if found=$(command -v "$tool" 2>/dev/null); then
    printf '%s' "$found"; return 0
  fi
  for dir in $SEARCH_DIRS; do
    if [ -x "$dir/$tool" ]; then printf '%s' "$dir/$tool"; return 0; fi
  done
  return 1
}

version_of() {
  "$1" -version 2>/dev/null | head -n 1 | sed 's/ Copyright.*//' || printf 'unknown'
}

# ------------------------------------------------------------------- platform
OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM="macOS" ;;
  Linux)  PLATFORM="Linux" ;;
  *)
    printf '%s\n' "This script covers macOS and Linux. On Windows run setup.ps1 instead." >&2
    exit 2 ;;
esac

printf '%sLaxtic Studios dependency setup%s\n' "$BOLD" "$RESET"
note "$PLATFORM ($(uname -m))"

# --------------------------------------------------------------- what is here
head_ "Checking what you already have"

MISSING=""
if FFMPEG_BIN=$(find_tool ffmpeg); then
  ok "ffmpeg   $FFMPEG_BIN"
  note "         $(version_of "$FFMPEG_BIN")"
else
  bad "ffmpeg   not found"
  MISSING="ffmpeg"
fi

if FFPROBE_BIN=$(find_tool ffprobe); then
  ok "ffprobe  $FFPROBE_BIN"
else
  bad "ffprobe  not found"
  MISSING="ffmpeg"     # ffprobe ships with ffmpeg; installing ffmpeg fixes both
fi

# On Linux the AppImage additionally needs FUSE 2 to mount itself. Ubuntu 24.04
# and its derivatives dropped libfuse.so.2, and the only symptom is the
# AppImage refusing to start with a message about "dlopen(): libfuse.so.2",
# which reads like a broken download rather than a missing library.
NEED_FUSE=0
if [ "$PLATFORM" = "Linux" ]; then
  if ls /usr/lib/*/libfuse.so.2 /usr/lib/libfuse.so.2 >/dev/null 2>&1; then
    ok "libfuse2 present (needed only by the .AppImage)"
  else
    warn "libfuse2 not found the .AppImage will not start without it"
    note "         the .deb and .rpm do not need it"
    NEED_FUSE=1
  fi
fi

if [ -z "$MISSING" ] && [ "$NEED_FUSE" -eq 0 ]; then
  head_ "Nothing to do"
  printf '  Laxtic Studios has everything it needs.\n\n'
  exit 0
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  head_ "Something is missing"
  printf '  Run %s./setup.sh%s to install it.\n\n' "$BOLD" "$RESET"
  exit 1
fi

# ------------------------------------------------------- the install command
# One package manager, chosen from what is actually on this machine. The
# command is printed before it runs, every time, including the sudo.
CMD=""
MANAGER=""
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then SUDO="sudo "; fi
fi

if [ "$PLATFORM" = "macOS" ]; then
  if command -v brew >/dev/null 2>&1; then
    MANAGER="Homebrew"
    CMD="brew install ffmpeg"
  else
    head_ "Homebrew is not installed"
    cat <<'EOS'
  ffmpeg on macOS comes from Homebrew, and Homebrew is not on this machine.

  Installing Homebrew changes more of your system than this script should do
  on its own, so here is the command to install it. Run it, then run this
  script again:

      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  Prefer not to use Homebrew? Any ffmpeg will do. Put it anywhere on your PATH,
  or point the app straight at it:

      export FFMPEG_PATH=/full/path/to/ffmpeg

EOS
    exit 1
  fi
else
  if   command -v apt-get >/dev/null 2>&1; then MANAGER="apt";    CMD="${SUDO}apt-get update && ${SUDO}apt-get install -y ffmpeg"
  elif command -v dnf     >/dev/null 2>&1; then MANAGER="dnf";    CMD="${SUDO}dnf install -y ffmpeg"
  elif command -v yum     >/dev/null 2>&1; then MANAGER="yum";    CMD="${SUDO}yum install -y ffmpeg"
  elif command -v pacman  >/dev/null 2>&1; then MANAGER="pacman"; CMD="${SUDO}pacman -S --needed --noconfirm ffmpeg"
  elif command -v zypper  >/dev/null 2>&1; then MANAGER="zypper"; CMD="${SUDO}zypper install -y ffmpeg"
  elif command -v apk     >/dev/null 2>&1; then MANAGER="apk";    CMD="${SUDO}apk add ffmpeg"
  else
    head_ "No package manager I recognise"
    cat <<'EOS'
  I looked for apt-get, dnf, yum, pacman, zypper and apk and found none of
  them, so I cannot install ffmpeg for you without guessing.

  Install ffmpeg however this distribution does it, then run this script again
  to confirm. Or point the app straight at a copy you already have:

      export FFMPEG_PATH=/full/path/to/ffmpeg

EOS
    exit 1
  fi

  # Fold the AppImage's FUSE library into the same install, so there is one
  # password prompt rather than two.
  if [ "$NEED_FUSE" -eq 1 ]; then
    case "$MANAGER" in
      apt)    CMD="$CMD && { ${SUDO}apt-get install -y libfuse2 || ${SUDO}apt-get install -y libfuse2t64; }" ;;
      dnf)    CMD="$CMD && ${SUDO}dnf install -y fuse-libs" ;;
      yum)    CMD="$CMD && ${SUDO}yum install -y fuse-libs" ;;
      pacman) CMD="$CMD && ${SUDO}pacman -S --needed --noconfirm fuse2" ;;
      zypper) CMD="$CMD && ${SUDO}zypper install -y libfuse2" ;;
      apk)    CMD="$CMD && ${SUDO}apk add fuse" ;;
    esac
  fi
fi

head_ "What I would like to run"
printf '  %s%s%s\n' "$BOLD" "$CMD" "$RESET"
note "  package manager: $MANAGER"
if [ -n "$SUDO" ]; then note "  sudo will ask for your password"; fi

if [ "$ASSUME_YES" -ne 1 ]; then
  printf '\n  Run it? [y/N] '
  read -r reply </dev/tty || reply=""
  case "$reply" in
    y|Y|yes|YES) ;;
    *) printf '\n  Nothing was installed.\n\n'; exit 1 ;;
  esac
fi

head_ "Installing"
if ! eval "$CMD"; then
  head_ "That did not work"
  printf '  The command above failed. The output from your package manager is\n'
  printf '  just above this message and will say why.\n\n'
  exit 1
fi

# ---------------------------------------------------------------- confirm it
head_ "Checking again"
FAILED=0
hash -r 2>/dev/null || true
for tool in ffmpeg ffprobe; do
  if bin=$(find_tool "$tool"); then
    ok "$tool  $bin"
  else
    bad "$tool  still not found"
    FAILED=1
  fi
done

if [ "$FAILED" -eq 1 ]; then
  printf '\n  It installed, but the binary is not anywhere the app looks.\n'
  printf '  Find it with %swhich ffmpeg%s and tell the app where it is:\n\n' "$BOLD" "$RESET"
  printf '      export FFMPEG_PATH=/full/path/to/ffmpeg\n\n'
  exit 1
fi

head_ "Done"
printf '  Laxtic Studios has everything it needs. Open the app and export something.\n\n'
