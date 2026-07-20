# SPDX-FileCopyrightText: 2026 David Rabkin
# SPDX-License-Identifier: 0BSD

# Repository Guidelines

`shellbase` is a POSIX-oriented shell framework (`lib/base.sh`) that scripts
source for logging, validation, signal handling, garbage collection, and
concurrent-instance support.

## Project Structure & Module Organization

`lib/base.sh` is the core POSIX-oriented library and the main artifact shipped
by this repository. `app/` contains helper scripts such as `install`, `update`,
and executable test cases named `test-*-ok` and `test-*-no`. Container
coverage lives under `container/<distro>/Containerfile`, and CI/lint
configuration lives in `.github/workflows/` and `.github/styles/`. Treat
`.redo/` as build metadata for the `redo` workflow, not hand-edited source.

## Build, Test, and Development Commands

This project uses `redo` (or `goredo`) as the primary task runner. `make` is only
a thin proxy.

- `redo all`: run the default build target.
- `redo lint`: run `actionlint`, `checkmake`, `dash`, `hadolint`, `mksh`,
  `reuse`, `shellcheck`, `shfmt`, `typos`, `vale`, `yamllint`, and `zizmor`.
- `redo test`: execute unit tests against the shells installed locally.
- `redo test-container`: run the test suite inside the supported container
  images.
- `./app/install`: install `lib/base.sh` into the expected local path.
- `./app/update`: lint `README.adoc`'s function links against `lib/base.sh`;
  add `--action` to regenerate them.

Use `make test` only if you need the compatibility wrapper.

`./app/update` requires GNU grep. On macOS, run it with GNU grep first on
`PATH` (for example
`PATH=/opt/homebrew/opt/grep/libexec/gnubin:$PATH ./app/update --action`); with the
BSD grep on `PATH` by default, its GNU-grep guard exits 0 quietly and leaves
`README.adoc` untouched instead of failing loudly.

## Coding Style & Naming Conventions

Write shell as portable `sh` first. Keep Bash-specific features out unless the
file already depends on them. Follow the existing editor hints: 2-space
indentation, no tabs, and an approximately 79-character text width. Every
script opens with the same header shape: the `#!/bin/sh` shebang (omitted in
`*.do` files, which `redo` executes directly), the
`# vi: lbr noet sw=2 ts=2 tw=79 wrap` modeline, the two SPDX lines, then any
`shellcheck disable` block or description comment, before sourcing
`lib/base.sh`. Match this layout when adding a new file. Public
functions in `lib/base.sh` are unprefixed, internal helpers use `base_`, and
global variables use the `BASE_` prefix. Name local variables with no more
than three letters, for example `cnt`, `dly`, or `err`. Keep new test files
aligned with the current pattern, for example `app/test-realpath-ok`. Write
comments in third-person singular and start every comment with a capital
letter. Do not place comments inside function bodies. Keep all of a function's
commentary in the single comment block immediately above its name. Avoid
semicolons in comment and prose text. Split the clauses into separate sentences
instead.

Write a `shellcheck disable` directive on its own line rather than as a
trailing comment, preceded by a description line ending with a colon, and
indent the directive one extra space so it reads as subordinate to the
description. For example, `# Uses variables in the printf format string:` is
followed by `#  shellcheck disable=SC2059`.

For `printf` format strings, stay with backslash-escape form (e.g.
`printf %s\\n`) only when it takes less source characters than the
single-quoted form (e.g. `printf '%s\n'`). When both forms are the same
length or the quoted form is shorter, prefer the quoted form for
readability.

When invoking a command that offers both a short and a long form of a flag,
prefer the long form (for example `--action` over `-a`, `--force` over `-f`)
for readability, both in scripts and in documentation examples. Fall back to
the short form only when the command has no long-form equivalent.

Order function definitions with `main()` first (immediately after the
script-level setup), then the remaining functions in strict
alphabetical order by name. This applies to both `lib/base.sh` (public
functions alphabetical, then `base_` helpers alphabetical, with no
`main`) and to app scripts that define their own `main()`.

`README.adoc` links every public function to its exact line in
`lib/base.sh` (for example `{url-base}#L58[`aud_only`]`). Any edit to
`lib/base.sh` that shifts line numbers requires running `./app/update --action`
to regenerate the alphabetical function-list block; the `log`, `loge`,
`logw`, and `prettytable` prose links elsewhere in `README.adoc` are
hand-maintained and must be fixed manually.

## Testing Guidelines

Add or update an executable script in `app/` for every behavior change. Use
`*-ok` for success cases and `*-no` for failure paths. Run `redo test` before
submitting. Run `redo test-container` when changing portability-sensitive shell
logic, container files, or CI behavior. Keep tests deterministic and compatible
with multiple Unix-like shells.

Test scripts run under `set -o errexit`, so a bare failing call ends the
script before any check on its exit code runs. Route expected failures
through `|| ret=$?` and compare `ret` afterward. In `*-no` scripts, assert by
appending `|| exit 0` to the check itself, so an unexpected success falls
through to `exit 0` and the test harness — which expects a `*-no` script to
fail — flags it.

## Commit & Pull Request Guidelines

Before committing, update `BASE_VERSION` in `lib/base.sh`,
`BASE_APP_VERSION` in every other changed file that declares it, and the
`SPDX-FileCopyrightText` year in every changed file — but only when the
file has a substantive change. Never bump the year or version by itself. If a
refactor pass ends up making no meaningful change to a file, revert the
year/version edit too. A metadata-only diff is noise. Versions are
date-based (`0.9.YYYYMMDD`); same-day commits share the value, so do not
re-bump a version already set to today's date.

Use Conventional Commits for all commits created by the agent, especially
scoped forms such as `build(deps): ...` and `chore(deps): ...`. Prefer concise,
imperative subjects with a meaningful scope when one exists. Do not add AI
attribution, tool signatures, generated-by trailers, or AI co-author metadata
to commits, pull requests, issues, or code comments. Pull requests should
explain the user-visible change, note any portability implications, and confirm
the relevant `redo lint` and `redo test` results. Link related issues when
applicable. UI screenshots are usually unnecessary for this repository.
