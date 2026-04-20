---
title: Development
layout: default
nav_order: 6
permalink: /develop/
---

# Development

Setup instructions, build workflow, test suite, debugging tips, and code-style conventions live in [CONTRIBUTING.md](https://github.com/gwelr/ttyx_/blob/master/CONTRIBUTING.md) at the repository root. Keeping the canonical copy there means GitHub auto-links it from new-issue and new-PR pages, so first-time contributors see it without needing to browse the docs site.

## Quick links

- [**CONTRIBUTING.md**](https://github.com/gwelr/ttyx_/blob/master/CONTRIBUTING.md) — full contributor guide: prerequisites, build, run-from-builddir, tests, debugging, style, PR workflow, codebase orientation.
- [**Install page**]({{ site.baseurl }}/install/) — user-facing install path, for when you just want to compile and run.
- [**debug-ttyx.sh**](https://github.com/gwelr/ttyx_/blob/master/debug-ttyx.sh) — wrapper that launches the build-dir binary under gdb with sensible defaults (signal handles, schema dir, XDG paths, single-instance handling).
- [**Issue tracker**](https://github.com/gwelr/ttyx_/issues) — bug reports and feature requests.

## At a glance

| Task | Command |
|------|---------|
| Build (Meson, debug) | `meson setup builddir --buildtype=debug && ninja -C builddir` |
| Build (Dub) | `dub build --compiler=ldc2` |
| Run unit tests | `meson test -C builddir --print-errorlogs` |
| Run from build dir | `./debug-ttyx.sh` |
| Analyze most recent crash | `./debug-ttyx.sh --core` |
