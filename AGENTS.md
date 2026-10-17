# SPDX-FileCopyrightText: 2026 David Rabkin
# SPDX-License-Identifier: 0BSD

# Repository Guidelines

`shellbase` is a POSIX-oriented shell framework (`lib/base.sh`) that scripts
source for logging, validation, signal handling, garbage collection, and
concurrent-instance support.

Read the shared rules at
https://raw.githubusercontent.com/rdavid/prompt/master/README.txt
before starting any task, unless they are already loaded.

## Structure

`lib/base.sh` is the core POSIX-oriented library and the main artifact shipped
by this repository. `app/` contains helper scripts such as `install`, `update`,
and executable test cases named `test-*-ok` and `test-*-no`. Container
coverage lives under `container/<distro>/Containerfile`, and CI/lint
configuration lives in `.github/workflows/` and `.github/styles/`. Treat
`.redo/` as build metadata for the `redo` workflow, not hand-edited source.

## Build

This project uses `redo` (or `goredo`) as the primary task runner. `make` is only
a thin proxy.

- `redo all`: run the default build target.
- `redo lint`: run `actionlint`, `checkmake`, `conform`, `dash`, `hadolint`,
  `mksh`, `reuse`, `shellcheck`, `shfmt`, `typos`, `vale`, `yamllint`, and
  `zizmor`.
- `redo test`: execute unit tests against the shells installed locally.
- `redo test-container`: run the test suite inside the supported container
  images.
- `./app/install`: install `lib/base.sh` into the expected local path.
- `./app/update`: lint `README.adoc`'s function links against `lib/base.sh`.
  Add `--action` to regenerate them.

Use `make test` only if you need the compatibility wrapper.

`./app/update` requires GNU grep. On macOS, run it with GNU grep first on
`PATH` (for example
`PATH=/opt/homebrew/opt/grep/libexec/gnubin:$PATH ./app/update --action`). With
the BSD grep on `PATH` by default, its GNU-grep guard exits 0 quietly and
leaves `README.adoc` untouched instead of failing loudly.

## Style

Every script opens with the same header shape: the `#!/bin/sh` shebang
(omitted in `*.do` files, which `redo` executes directly), the
`# vi: lbr noet sw=2 ts=2 tw=79 wrap` modeline, the two SPDX lines, then any
`shellcheck disable` block or description comment, before sourcing
`lib/base.sh`. Match this layout when adding a new file. Use 2-space
indentation and no tabs. Public functions in `lib/base.sh` are unprefixed,
internal helpers use `base_`, and global variables use the `BASE_` prefix.
Name local variables with no more than three letters, for example `cnt`,
`dly`, or `err`. Keep new test files aligned with the current pattern, for
example `app/test-realpath-ok`.

In `lib/base.sh`, list public functions alphabetically, then `base_` helpers
alphabetically, with no `main`.

`README.adoc` links every public function to its exact line in
`lib/base.sh` (for example `{url-base}#L58[`aud_only`]`). Any edit to
`lib/base.sh` that shifts line numbers requires running `./app/update --action`
to regenerate the alphabetical function-list block. The `log`, `loge`,
`logw`, and `prettytable` prose links elsewhere in `README.adoc` are
hand-maintained and must be fixed manually.

## Testing

Add or update an executable script in `app/` for every behavior change. Use
`*-ok` for success cases and `*-no` for failure paths. Run
`redo test-container` when changing portability-sensitive shell logic,
container files, or CI behavior.

In `*-no` scripts, assert by appending `|| exit 0` to the check itself, so an
unexpected success falls through to `exit 0` and the test harness, which
expects a `*-no` script to fail, flags it.

## Commits

Before committing, update `BASE_VERSION` in `lib/base.sh`,
`BASE_APP_VERSION` in every other changed file that declares it, and the
`SPDX-FileCopyrightText` year in every changed file, but only when the file
has a substantive change. Versions are date-based (`0.9.YYYYMMDD`).
