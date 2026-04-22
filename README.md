[![Build Test](https://github.com/gwelr/ttyx_/actions/workflows/build-test.yml/badge.svg)](https://github.com/gwelr/ttyx_/actions/workflows/build-test.yml)

<p align="center">
  <img src="data/hey-ttyx.svg" alt="ttyx_ logo" width="128">
</p>

# ttyx_

**Tilix, but with a pulse.**

ttyx_ is an actively maintained fork of [Tilix](https://github.com/gnunn1/tilix), the tiling terminal emulator for Linux. The original project did amazing work, but with development stalled and a growing list of unaddressed bugs, ttyx_ picks up where it left off — with a focus on security hardening and responsiveness to modern Linux desktops.

📖 **[Documentation site](https://gwelr.github.io/ttyx_/)** — install, manual, security reference, migration guide, changelog.

## What you get

- **Tiling terminal** — split horizontally, vertically, nest arbitrarily. Drag and drop between windows. Save and restore layouts as sessions. Synchronized input across terminals.
- **Security-conscious by default** — paste review with dangerous-command detection, clipboard auto-clear, root/SSH visual indicators, core-dump protection, in-memory-only scrollback, one-shortcut `Secure Clear`. Full list on the [Security features page](https://gwelr.github.io/ttyx_/security/).
- **Actively maintained** — crash fixes, new color schemes, release-build optimizations, a growing unit-test suite. See [What's new vs Tilix](https://gwelr.github.io/ttyx_/whats-new/) for the feature-level comparison and the [changelog](https://gwelr.github.io/ttyx_/changelog/) for per-release notes.

## Install

End users: grab the signed Flatpak bundle from the [latest release](https://github.com/gwelr/ttyx_/releases/latest) — the [Install page](https://gwelr.github.io/ttyx_/install/) walks through signature verification and install.

Distro packagers and developers: the same page covers source builds with Meson (primary, matches CI) and Dub.

## Migrating from Tilix

ttyx_ migrates your session files and reads existing saved passwords automatically on first run; both `TTYX_ID` and `TILIX_ID` are set so existing shell-integration scripts keep working. See [Migrating from Tilix](https://gwelr.github.io/ttyx_/migrating/) for the full checklist and rollback steps.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) — build, run, test, debug, code style, and PR conventions.

**Issues** must include what happened, what was expected, reproduction steps, and environment details (distro, VTE version, display server). Incomplete issues will be closed without review.

**Pull requests** are the best way to get something changed. PRs may be declined if they don't fit the project direction — no hard feelings. If you disagree, fork it. That's how this project started too.

This is a freetime project. No support is provided.

## Credits

ttyx_ is built on the shoulders of [Tilix](https://github.com/gnunn1/tilix) by Gerald Nunn and its contributors. Huge thanks to everyone who made the original project what it is.

## License

[MPL-2.0](LICENSE)
