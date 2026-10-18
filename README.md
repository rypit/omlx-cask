# omlx-cask

A Homebrew **cask** that installs [oMLX](https://github.com/jundot/omlx) — a
production-ready LLM server for Apple Silicon — from the prebuilt `.dmg` app
bundles published on the project's GitHub releases.

This complements the existing **formula** in the upstream repo
(`brew install omlx`, which builds the CLI/server from source): the cask
installs the signed GUI app (`oMLX.app`, which also bundles the server and CLI),
while the formula remains the source-built CLI. The two are designed to coexist.

## Install

```sh
brew tap rypit/omlx-cask https://github.com/rypit/omlx-cask
brew install --cask omlx-cask
```

The cask does not pin a version. On each install it resolves the **latest
non-development release** from the GitHub releases feed, so `brew upgrade` pulls
in newer releases automatically. The correct build for your macOS version is
selected automatically:

| macOS                  | Asset                               |
| ---------------------- | ----------------------------------- |
| 15 (Sequoia)           | `oMLX-<version>-macos15-sequoia.dmg` |
| 26 (Tahoe) and newer   | `oMLX-<version>-macos26-27.dmg`      |

oMLX is Apple-Silicon only (`arm64`) and requires macOS 15 or newer.

Because the version is resolved dynamically, checksums are not pinned or
verified (`sha256 :no_check`). This is intentional for a personal tap, but means
the cask is not eligible for the official `Homebrew/homebrew-cask` repo.

## Choosing what to install

`HOMEBREW_OMLX_VERSION` controls which release the cask installs:

| `HOMEBREW_OMLX_VERSION` | Installs |
| ----------------------- | -------- |
| _unset_ (default)       | latest **stable** release (excludes `dev`/`rc`) |
| `rc`                    | latest **stable-or-rc** release (excludes `dev`) |
| `pre` (or `latest`)     | latest release **including** `dev` and `rc` prereleases |
| an exact tag, e.g. `0.6.4` or `0.7.1.dev1` | that specific release |

```sh
# latest stable
brew install --cask omlx-cask

# latest release candidate (no dev builds)
HOMEBREW_OMLX_VERSION=rc brew install --cask omlx-cask

# latest dev/rc prerelease
HOMEBREW_OMLX_VERSION=pre brew install --cask omlx-cask

# a specific release (leading "v" optional)
HOMEBREW_OMLX_VERSION=0.6.4 brew install --cask omlx-cask
```

An exact tag skips the releases-feed lookup entirely. Only install versions you
trust (checksums are not verified).

> Homebrew only forwards environment variables prefixed with `HOMEBREW_` to
> cask definitions, which is why the variable is named `HOMEBREW_OMLX_VERSION`
> rather than `OMLX_VERSION`.

## The `omlx` CLI

The cask links an `omlx` command onto your `PATH` (from the CLI bundled inside
`oMLX.app`), so a plain `brew install --cask omlx-cask` gives you both the app and the
CLI.

If the `omlx` **formula** (`brew install omlx`) is also installed, it owns the
`omlx` name instead and Homebrew skips the cask's link with a warning — the
formula wins. Either way you also get the shim the app installs at
`~/.omlx/bin/omlx` the first time you launch it.

## Uninstall

```sh
brew uninstall --cask omlx-cask        # remove the app
brew uninstall --cask --zap omlx-cask  # also remove ~/.omlx, ~/.config/omlx, caches, prefs
```

`--zap` intentionally leaves the shared Hugging Face model cache
(`~/.cache/huggingface`) in place.

## Notes

- `brew audit --cask --online omlx-cask` reports one benign finding: the app bundle
  declares `LSMinimumSystemVersion` 15.0, while the cask gates the macOS-26/27
  build behind `on_tahoe`. Upstream ships distinct per-macOS builds (they differ
  in the bundled MLX/Metal frameworks) that both carry the same
  `LSMinimumSystemVersion`, so the audit's inferred minimum can't match on every
  OS. It does not affect installation.
