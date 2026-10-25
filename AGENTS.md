# Repository Guidelines

`shellbase` is a POSIX-oriented shell framework (`lib/base.sh`) that scripts
source for logging, validation, signal handling, garbage collection, and
concurrent-instance support.

Read the shared rules at
https://raw.githubusercontent.com/rdavid/prompt/master/README.txt
before starting any task, unless they are already loaded.

## Structure

`lib/base.sh` is the core POSIX-oriented library and the main artifact shipped
by this repository.
`app/` contains helper scripts such as `install`, `update`, and executable
test cases named `test-*-ok` and `test-*-no`.
Container coverage lives under `container/<distro>/Containerfile`.
CI and lint configuration lives in `.github/workflows/` and `.github/styles/`.
Targets live in `*.do` files, which `redo` executes directly.
Treat `.redo/` as build metadata for the `redo` workflow, not hand-edited
source.

## Build

This project uses `redo` (or `goredo`) as the primary task runner.
`make` is only a thin proxy, so use `make test` only if you need the wrapper.

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

`./app/update` requires GNU grep.
On macOS, run it with GNU grep first on `PATH`.
For example:
`PATH=/opt/homebrew/opt/grep/libexec/gnubin:$PATH ./app/update --action`.
With the BSD grep on `PATH` by default, its GNU-grep guard exits 0 quietly.
It then leaves `README.adoc` untouched instead of failing loudly.

## Style

Scripts follow the shared header layout, omit the shebang in `*.do` files,
and source `lib/base.sh` right after the header.
Use 2-space indentation and no tabs.
Public functions in `lib/base.sh` are unprefixed.
Internal helpers use `base_`, and global variables use the `BASE_` prefix.
Name local variables in functions with no more than three letters, for
example `cnt`, `dly`, or `err`.
Keep script-level variables in `*.do` files capitalized, for example `STP`
or `EXE`.
Keep new test files aligned with the current pattern, for example
`app/test-realpath-ok`.

In `lib/base.sh`, list public functions alphabetically, then `base_` helpers
alphabetically, with no `main`.

`README.adoc` links every public function to its exact line in
`lib/base.sh` (for example `{url-base}#L58[`aud_only`]`).
Any edit to `lib/base.sh` that shifts line numbers requires running
`./app/update --action` to regenerate the alphabetical function-list block.
The `log`, `loge`, `logw`, and `prettytable` prose links elsewhere in
`README.adoc` are hand-maintained and must be fixed manually.

## Testing

Add or update an executable script in `app/` for every behavior change.
Use `*-ok` for success cases and `*-no` for failure paths.
Run `redo test-container` when changing portability-sensitive shell logic,
container files, or CI behavior.

In `*-no` scripts, assert by appending `|| exit 0` to the check itself.
An unexpected success then falls through to `exit 0`.
The test harness expects a `*-no` script to fail, so it flags that case.

## Commits

Follow the shared Licensing rules for versions and copyright years.
The version variable in `lib/base.sh` is `BASE_VERSION`, not
`BASE_APP_VERSION`.
Run `redo lint` and `redo test` before committing.
