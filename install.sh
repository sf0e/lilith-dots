#!/bin/sh
# lilith-dots installer
# fetches the dotfiles, installs the packages, builds & installs lilith.
set -e

REPO="sf0e/lilith-dots"
BRANCH="main"
LILITH_URL="https://github.com/ohto121/lilith"
LILITH_REV="4acbf2871316dce751a5448ea799953bf0bd3ad8"
BUILD_DIR="${LILITH_BUILD_DIR:-$HOME/.local/src/lilith}"

info()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()   { printf '\033[1;31mXX\033[0m %s\n' "$*" >&2; exit 1; }

# --- find sudo or doas ---
if command -v sudo >/dev/null 2>&1; then
	ESC="sudo"
	ESC_CACHE="sudo -v"
elif command -v doas >/dev/null 2>&1; then
	ESC="doas"
	ESC_CACHE="doas true"
else
	die "neither sudo nor doas found; install one and retry"
fi

# --- sanity checks ---
[ "$(id -u)" -eq 0 ] && die "run this as your normal user, not root"
command -v emerge >/dev/null 2>&1 || warn "emerge not found; skipping packages (not Gentoo?)"
command -v git   >/dev/null 2>&1 || die "git is required"
command -v curl  >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || die "curl or wget is required"

# --- one elevated prompt up front, then keep it alive while we work ---
$ESC_CACHE || die "could not elevate with $ESC"
( while true; do $ESC -n true >/dev/null 2>&1 || $ESC_CACHE >/dev/null 2>&1; sleep 60; done ) &
KEEPER=$!
trap 'kill "$KEEPER" 2>/dev/null || true' EXIT INT TERM

# --- fetch this repo ---
TMP="$(mktemp -d)"
trap 'kill "$KEEPER" 2>/dev/null || true; rm -rf "$TMP"' EXIT INT TERM

info "fetching $REPO"
if command -v curl >/dev/null 2>&1; then
	curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar -xz -C "$TMP"
else
	wget -qO- "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar -xz -C "$TMP"
fi
SRC="$TMP/$(ls "$TMP")"

# --- emerge the package list ---
if command -v emerge >/dev/null 2>&1; then
	PKGS="$(grep -Ev '^\s*(#|$)' "$SRC/packages.list" | tr '\n' ' ')"
	info "emerging: $PKGS"
	$ESC emerge -av $PKGS
else
	warn "skipping package install: emerge not found"
fi

# --- clone / sync lilith at the pinned rev ---
info "preparing lilith source in $BUILD_DIR"
if [ -d "$BUILD_DIR/.git" ]; then
	git -C "$BUILD_DIR" fetch --quiet origin
else
	mkdir -p "$BUILD_DIR"
	git clone --quiet "$LILITH_URL" "$BUILD_DIR"
fi
git -C "$BUILD_DIR" checkout --quiet "$LILITH_REV"

# --- apply the patches ---
info "applying patches"
cd "$BUILD_DIR"
for p in "$SRC"/lilith/patches/*.patch; do
	git apply --whitespace=nowarn "$p" || die "failed to apply $p"
done

# --- drop in the config ---
info "installing config"
cp "$SRC/lilith/config.h" "$BUILD_DIR/config.h"
cp "$SRC/lilith/config.mk" "$BUILD_DIR/config.mk"
cp "$SRC/lilith/config/"*.h "$BUILD_DIR/config/"

# --- build & install ---
info "building lilith"
make clean >/dev/null 2>&1 || true
make
info "installing lilith"
$ESC make install

info "done. start lilith from a tty (or your display manager)."
