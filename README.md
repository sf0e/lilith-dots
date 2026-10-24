# lilith-dots

my config for [lilith](https://github.com/ohto121/lilith) — the rose-theme
rice plus the patches i run on top of it, and the emerge package list for the
whole setup.

## what's in here

```
install.sh       installer (emerge packages, build + install lilith)
packages.list    emerge atoms for everything this rice uses
lilith/config/   config.h, config.mk and the config/*.h headers
lilith/patches/  git diffs applied on top of ohto121/lilith
```

- `lilith/config/` is the full config: colors (the rose theme), bar, keys,
  input, animation, spawn region.
- `lilith/patches/` are the source changes i run — foreign-toplevel-list,
  image-capture, and `spawnregioncmd` (drag a rectangle and the window opens
  inside it). the patches are generated against lilith at
  `4acbf2871316dce751a5448ea799953bf0bd3ad8`.

## install

```
curl -fsSL https://raw.githubusercontent.com/sf0e/lilith-dots/main/install.sh | sh
```

the installer asks for your password **once** (it auto-detects `sudo` or
`doas`), then emerges every package in `packages.list`, clones lilith, applies
the patches, drops in the config, and `make install`s it to `/usr/local/bin`.

build source ends up in `~/.local/src/lilith` (override with
`LILITH_BUILD_DIR`) so you can edit and rebuild.

## notes

- assumes Gentoo (emerge). on another distro it skips the package step and
  just builds lilith — install the build deps yourself.
- `gui-libs/wlroots` may need `~amd64` accepting in some trees.
