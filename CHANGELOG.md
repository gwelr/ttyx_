# Changelog

All notable changes to **ttyx_** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security
- **Confirmation prompt before a restored session runs an embedded command** — a session file's per-terminal `overrideCommand` was executed as the terminal's child process the moment the session loaded, with no prompt, so opening a crafted or shared `.json` (via Open Session or `--session`) silently ran an attacker-chosen command in an attacker-chosen directory. Restoring a session that carries an embedded command now shows a modal confirmation naming the command, defaulting to the safe choice; declining opens a normal shell. Only the session-restore path prompts — CLI (`-e`/`-x`) and profile custom commands are trusted and unaffected. The command is shown as plain text so it cannot inject Pango markup into the dialog.
- **Custom-link and trigger commands now shell-quote attacker-controlled substitutions** — clicking a custom link, and the `EXECUTE_COMMAND`/`RUN_PROCESS` triggers, substituted regex match tokens (`$0..$N`, drawn from terminal output) and terminal variables (`${title}`, `${hostname}`, ... — several remote-settable via OSC) into a string handed to `/bin/sh -c` with no escaping. A captured or OSC-set value containing shell metacharacters (`; rm -rf ~`, `` `…` ``, `$(…)`) therefore injected into the command — for custom links on a single click, for triggers automatically (trigger firing requires a Tilix-patched VTE). Every substituted value now passes through `g_shell_quote` via a new `replaceMatchTokensQuoted` helper and a shell-quoting mode of `replaceVariables`, so values become inert shell words while the user's own template syntax (pipes, `&&`, redirects) is preserved. Display/state/notification actions are unaffected (still substituted verbatim). As a side effect the trigger handler no longer mutates the shared trigger object, so repeated fires are idempotent.
- **Paste sanitization now applied on every paste path** — `stripPasteEscapes` produced a sanitized string, but the default paste path (with neither `paste-strip-first-char` nor `paste-strip-trailing-whitespace` enabled, the shipped default) fell through to VTE's `pasteClipboard()`/`pastePrimary()`, which re-read the *raw* selection from the OS and discarded the sanitized result — contradicting the function's "unconditional sanitization" contract. All paste branches now feed the sanitized text through `vte_terminal_paste_text`, which still applies bracketed-paste wrapping, so editors keep receiving properly-bracketed pastes.
- **Bracketed-paste stripping hardened against split/overlapping markers** — `stripPasteEscapes` ran each regex a single, non-overlapping, non-re-scanning pass, so removing one match could splice the surrounding bytes into a freshly-formed marker (e.g. `\x1b[20` + `\x1b[201~` + `1~` collapsed to a live `\x1b[201~` after the inner removal, terminating bracketed-paste mode early and letting the trailing bytes run as keystrokes). Stripping now loops to a fixed point; each pass only deletes, so it is guaranteed to terminate.
- **Carriage return treated as a command submitter in paste checks** — `isPasteUnsafe`, the multi-line review gate, and the advanced-paste gate tested only for LF (`\n`), so a CR-terminated payload (`sudo reboot\r`) — which auto-executes just like LF — slipped past both the dangerous-command warning and the multi-line review dialog. A new `containsLineBreak` helper matches both LF and CR; unit tests cover the previously-evading cases.
- **Proxy credentials redacted in the spawn-failure log** — when a child process failed to spawn, `spawnTerminalProcess` dumped the full environment at error level (not gated behind verbose logging), including the `http_proxy`/`https_proxy` URLs that `setProxyEnv` builds with inline `user:password`. The environment dump now runs each entry through a new `redactEnvEntry` helper (secret/token/auth values replaced with a placeholder, proxy-URL userinfo stripped), and the argument dump strips URL userinfo.
- **OSC 8 hyperlinks are restricted to an allow-listed set of URI schemes** — an OSC 8 hyperlink carries an arbitrary URI chosen by whatever wrote to the terminal, and `openURI` handed it to the desktop URI handler (`MountOperation.showUri`) after only a `file://`-remote check — so a `javascript:`, `data:`, or scriptable custom scheme was opened blindly. Non-`file` URIs now pass through a new `isAllowedUriScheme` allowlist (http/https/ftp/ftps/sftp/file/mailto/news/nntp/telnet/webcal/sip/sips/h323 — the schemes the built-in link regexes produce); anything else is refused with a dialog. The CWD-in-browser action is unaffected (always a local `file://`).
- **Trigger regex input is bounded to mitigate ReDoS** — user-configured trigger patterns are matched with `std.regex` (a backtracking engine with no step/time limit that cannot be interrupted) against terminal output on the UI thread. With `unlimited` trigger lines or very wide lines, a catastrophic-backtracking pattern could hang the UI on adversarial output. The scanned text is now capped (keeping the most recent output) via a new `boundedTail` helper as defense-in-depth. Note: this path only runs on a Tilix-patched VTE, and the pattern is the user's own — the cap bounds input amplification, it does not make an arbitrary pattern safe.
- **Log redaction completeness** — the sensitive-key fragment list gained `pwd`, `key`, `private`, and `passphrase` (so `MYSQL_PWD`, `SSH_PRIVATE_KEY`, `GPG_KEY`, etc. are redacted), and `redactSensitive` now strips URL userinfo from *every* value, not just proxy-keyed ones — so a credential-bearing URL under an unrecognized key (e.g. `DATABASE_URL=postgres://u:pw@h/db`) no longer leaks. `cmdparams.d` now imports the redaction helper and strips URL userinfo from the parsed `--command`/`-e`, working-directory, cwd, and title values it re-logs at trace level (previously logged verbatim, unlike the raw argv which `app.d` already redacts).
- **Retrieved keyring passwords use non-pageable memory** — the password-insert path now calls `passwordLookupvNonpageableSync` instead of `passwordLookupvSync`, so a retrieved secret lives in memory libsecret keeps out of swap rather than ordinary pageable memory.

### Fixed
- **Crash reading the host shell from a malformed passwd entry** — `getHostShell` (Flatpak path) sliced `passwd.split(":")[6]` without checking the field count, throwing a `RangeError` on an entry with fewer than 7 fields. The field count is now guarded and the function returns null on a malformed entry.
- **Crash loading a session with a corrupt orientation value** — a session JSON whose paned `orientation` was neither 0 nor 1 was cast straight to GTK's `Orientation` enum and hit a `final switch`, throwing a `SwitchError`. Because that is an `Error` rather than an `Exception`, the session-load `catch (Exception)` did not catch it and the app crashed on opening a crafted or corrupt session file. Orientation is now validated by a testable `parseOrientation` helper that rejects out-of-range values so the load fails gracefully.
- **Crash reading a child process name from a malformed `/proc` stat** — `TerminalProcessQuery` sliced the `comm` field between `(` and `)` without checking they exist; a missing `)` made `lastIndexOf` return -1, which wrapped to `SIZE_MAX` in a `size_t` and threw a `RangeError` the `catch (FileException)` could not catch (reachable in the Flatpak path when the host toolbox returns empty/non-stat output). Parsing moved to a guarded, unit-tested `parseProcName` helper in `gx.util.proc` that returns null on malformed input.

## [1.2.0-beta.1] — 2026-04-29

First beta of the 1.2.0 release. Validation period before GA.

### Added
- **OSC 11 (dynamic background color) support** — apps like neovim and theme-switching scripts can now change the terminal background at runtime via `printf '\033]11;#rrggbb\007'`; reset with `printf '\033]111\007'`. ttyx_ no longer disables VTE's native background painting, so OSC 11 is honoured natively. The badge draw signal moved from the BEFORE phase to AFTER so badges still render on top of the terminal output (#47).
- Documentation site at <https://gwelr.github.io/ttyx_/> — built with Jekyll + just-the-docs, manual content adapted from upstream Tilix under MPL-2.0 (#59, #60, #61, #63, #64).
- Unit test coverage for the password manager row-removal path, extracted as `removeRowById` (#54).
- Unit tests for the proxy URL builder, sensitive-value redaction, and process introspection helpers (#55, #56, #58).

### Changed
- **`TerminalRegex` converted to a tagged union over `BuiltinRegex` / `CustomRegex`** — the previous flat struct carried a `command` field that was "only used for custom regex", a conditionally-meaningful field that nothing enforced at the type level. Splitting the two variants makes it impossible at compile time to attach a command to a builtin URL regex or to construct a custom-link regex without one (the `CustomRegex` constructor's `in` contracts require a non-empty pattern and a non-null command). The custom-link click handler in `Terminal.openURI` now dispatches via `match!` — the `command` access is reachable only inside the `CustomRegex` branch. UFCS accessors (`pattern`, `caseless`, `flavor`) keep call-site code at consumers that only need shared fields unchanged. Wire format and runtime behaviour unchanged. Mirrors the same pattern as #33's `SyncInputEvent` SumType conversion (#87).
- **Synchronized-input event payload converted to a tagged union** — `SyncInputEvent` is now a `std.sumtype.SumType` of `SyncKeyPressEvent`, `SyncTextEvent`, `SyncInsertTerminalNumberEvent`, `SyncResetEvent`, and `SyncResetAndClearEvent`. Each variant carries exactly the fields it needs and rejects null payloads via `in` contracts, so it is now impossible at compile time to construct a key-press event without an `Event` or a text event without a payload. The consumer in `Terminal.handleSyncInput` dispatches via `match!`, which is exhaustive at compile time — adding a future variant without handling it will fail to compile (#33).
- **Terminal serialisation centralised on a typed `TerminalSnapshot` struct** — replaces the ad-hoc JSON building that was scattered between `session.d` and `terminal.d`. Adding a persisted field is now a single struct change instead of coordinated edits in two files. Wire format unchanged; `Nullable!string` makes optional override fields explicit; the dead per-terminal `width`/`height` writes (never read on the per-terminal deserialise path) are dropped from the format. Lenient deserialisation: missing keys default-initialise, unknown keys are ignored. Verified by a golden-JSON roundtrip test (#34).
- **`enable-wide-handle` now defaults to `true`** — the splitter between split terminals is now wide by default, making it easier to see and grab on dark themes and HiDPI displays. Existing users who have explicitly toggled this preference are unaffected; only fresh installs and users who never touched it pick up the new default. Set to `false` to restore the previous 1-pixel splitter (#48).
- Extracted pure helpers out of the terminal widget module to reduce complexity and unlock testing: `pointInTriangle` → `gx.util.geometry`, `parsePairs` → `gx.util.string`, process introspection → `gx.util.proc` (#57, #58).
- Process root detection now goes through a single `readProcStatus` helper; the `/proc/[pid]/status` parser was previously duplicated across `monitor.d` and `activeprocess.d` (#58).
- Debug log path resolution now prefers `$XDG_RUNTIME_DIR/ttyx.log` over `/tmp/ttyx.log` when file logging is enabled (#55).

### Fixed
- **Triggers with an unrecognised action name are now skipped instead of silently rewritten to UpdateState** — the `TerminalTrigger` constructor used to fall through to `default: break;` on any unknown action name, leaving `action` at its enum init value (`UPDATE_STATE`). A typo, a stale config from a different fork, or a future schema migration with renamed actions would silently rewrite the user's trigger to a working-but-wrong UpdateState. The constructor now throws `UnknownTriggerActionException`; the loader in `Terminal.loadTriggers` catches and logs `Skipping trigger entry with unknown action 'X' (pattern 'Y')`. Note: this only affects users who have triggers configured (the trigger UI is gated behind a Tilix-patched VTE — see #95) (#88).
- **Trigger templates: `$0` now substitutes the whole match (not the first capture group)** — `replaceMatchTokens` had a `size_t` off-by-one underflow (`i - 1` on the first iteration wrapped to `size_t.max`), which silently shifted every token by one: `$0` got the first capture group, `$1` got the second, and the whole match was never substitutable. The function now iterates in reverse to also handle `$10`/`$1` correctly (without reverse iteration the `$1` pass would corrupt the start of `$10`, `$11`, ...). User-configured triggers that relied on the bugged behaviour will need their template indices shifted up by one (#84).
- **Maximized terminal not restored on session load** — loading a saved session whose JSON has `maximized: true` on a child no longer leaves the user looking at the half-empty Paned. Root cause: `gtk_stack_set_visible_child` is a silent no-op when the target child has never been shown, and on the restore path `parseSession` runs before `nb.showAll()` cascades show to the stack pages. Fixed by explicitly calling `show()` on the maximized stack page before switching to it; idempotent in the user-triggered Ctrl+Shift+X path. Pre-existing since the upstream Tilix 2017 implementation; surfaced in #91 during the #89 refactor smoke test (#91).
- **Password manager delete silently failed** — the delete button claimed success even when the keyring operation failed, and legacy-schema entries from the Tilix migration couldn't be deleted at all (#50, #54).
- **Proxy URL malformed** — the generated `http_proxy` URL had a redundant leading `@` before userinfo, which strict RFC-3986 parsers reject; credentials were also not percent-encoded, so passwords containing `@`, `:`, `/` broke the URL entirely (#51, #55).
- **`https_proxy` missing authentication** — the auth block was gated on `scheme == "http"` so the HTTPS proxy never received credentials even when configured (#51, #55).
- **Debian Testing CI build** — GtkD bindings were removed from Debian Testing's apt archive; CI now builds GtkD from source on that image (#49).
- **CI: LDC compiler installed from upstream tarball** — `ldc` is currently missing from Debian Testing during a transition. All container-based CI images (Debian Stable, Debian Testing, Ubuntu Noble) now install LDC 1.40.0 from the official `ldc-developers` GitHub release tarball instead of apt, so CI is no longer coupled to any one distro's apt archive. Same mitigation pattern as the GtkD-from-source fix from #49.

### Security
- **Config migration hardened against symlink attacks** — `migrateConfigBetween` now refuses to follow symlinks and skips existing target files during the Tilix → ttyx_ first-run migration (#49).
- **Sensitive values redacted in trace logs** — environment variables whose keys contain `password`/`token`/`secret`/`auth` are replaced with `[redacted]`; proxy URLs have their userinfo stripped before logging (#51, #55, #56).
- **Command-line arguments and hyperlink traces redacted** — URL userinfo is stripped from argv and from terminal hyperlink click events before they reach any log sink (#56).

## [1.1.1] — 2026-04-18

Maintenance release focused on identity: ttyx_ became its own project, with automatic migration for users coming from Tilix.

### Added
- **Automatic migration from Tilix on first run**: `~/.config/tilix/` is copied to `~/.config/ttyx/` (original kept as backup); libsecret entries stored under the old Tilix schema are still read and new passwords are written to the ttyx schema; both `TTYX_ID` and `TILIX_ID` are set in shells so existing shell integrations keep working.
- New "Migrating from Tilix" section in README.
- New "Troubleshooting" section covering stale icon caches and Wayland Quake-mode limitations.
- `ROADMAP.md` documenting vision and phase plan.

### Changed
- Renamed user-visible Tilix references in the Nautilus menu, shortcuts window, GSettings descriptions, icon filenames, and log/temp paths.
- Rewrote the man page under ttyx_ identity.
- Dropped 30 stale translation files that still carried Tilix-branded source strings.
- Release process simplified: ship only the Flatpak bundle with signed checksums. The hand-assembled binary tarball was dropped — distro packagers should build from source, Flatpak covers direct users.

### Fixed
- Color scheme list no longer shows duplicates when the same scheme exists in both user config and system data dirs (user config wins).
- Post-install script writes a minimal `index.theme` at the install prefix so `gtk-update-icon-cache` can generate a valid icon cache.
- AppStream metadata no longer includes stale Tilix release entries.

## [1.1.0] — 2026-04-15

A major security and performance release. ttyx_ positioned itself as a security-conscious tiling terminal emulator for Linux.

### Added
- **Paste protection** — bracketed-paste escape stripping (blocks `ESC[200~` / `ESC[201~` injection), multi-line paste review dialog, dangerous-command detection (`sudo`, `su`, `rm -rf`, `curl | bash`, `dd if=`, `mkfs`, `chmod 777`, fork bombs), per-paste warnings that appear every time rather than once per session.
- **Clipboard auto-clear** — clears clipboard after a configurable 5–300 s timeout to prevent sensitive data from lingering.
- **SSH session indicator** — blue tint and label when connected via ssh, scp, sftp, mosh, or sshfs.
- **Root indicator** — red tint and label when running with elevated privileges.
- **Core-dump protection** — `prctl(PR_SET_DUMPABLE, 0)` blocks `/proc/pid/mem` reads and core-dump generation; toggleable for debugging.
- **In-memory-only scrollback** — removed the unlimited scrollback option; capped at 256–999,999 lines, never written to disk.
- **Secure Clear** (`Ctrl+Shift+L`) — on-demand wipe of the scrollback buffer.
- 119 unit tests covering security, clipboard, rendering, and process-monitor modules.
- Security options consolidated under **Preferences → Advanced → Security** with descriptive labels.

### Changed
- **ProcessMonitor optimization** — idle CPU reduced from 1.4% to 0.1% by replacing full `/proc` scans with targeted foreground-process lookups.
- **Major terminal.d decomposition** — `terminal.d` (178 KB) had `ClipboardHandler`, `TerminalRenderer`, `ProcessQuery`, `SpawnHandler`, `FlatpakHostCommands` extracted.
- PreferenceRegistry pattern replaced the switch-based preference dispatch.

### Fixed
- GC crash when opening preferences on GLib 2.84+ (Flatpak environments).
- SSH and root indicators not clearing when the foreground process exits.
- Color scheme test when schemes are not installed in XDG paths.

## [1.0.2] — 2026-04-07

First release under the ttyx_ name.

### Added
- New tabs open next to the current tab (not at the end).
- Option to strip trailing whitespace on copy.
- Visual indicator when terminal is running as root.
- `~` and `@` added to default word-select characters.
- 8 new built-in color schemes: Catppuccin (Latte, Mocha), Dracula, Gruvbox (Dark, Light), Nord, One Dark, Tokyo Night.
- Comprehensive unit test suite across utility and core modules.

### Changed
- Release build optimizations: proper `-O3`, `-release`, `-inline`, `-boundscheck=off` flags for both meson and dub. Binary size dropped from 17 MB (debug) to 3.3 MB (release, stripped).

### Fixed
- Crash on malformed URIs in OSC 7 and drag-and-drop.
- Color schemes with `use-theme-colors` incorrectly shown as "Custom".
- Title bar markup rendering (`setText` instead of `setMarkup`).
- Focus stealing on terminal restart.
- Proxy host protocol prefix duplication.
- Empty clipboard text after stripping whitespace.
- Preferences dialog segfaults when changing profiles or closing the dialog.

## Attribution

ttyx_ is a fork of [Tilix](https://github.com/gnunn1/tilix) by Gerald Nunn, licensed under [MPL-2.0](LICENSE). Release history before 1.0.2 is part of the upstream Tilix project.
