# SPDX-FileCopyrightText: 2026 David Rabkin
# SPDX-License-Identifier: 0BSD

# Repository Guidelines

## Project Structure & Module Organization

`lib/base.sh` is the core POSIX-oriented library and the main artifact shipped
by this repository. `app/` contains helper scripts such as `install`, `update`,
and executable test cases named `test-*-ok` and `test-*-no`. Container
coverage lives under `container/<distro>/Containerfile`, and CI/lint
configuration lives in `.github/workflows/` and `.github/styles/`. Treat
`.redo/` as build metadata for the `redo` workflow, not hand-edited source.

## Build, Test, and Development Commands

This project uses `redo` (or `goredo`) as the primary task runner; `make` is only
a thin proxy.

- `redo all`: run the default build target.
- `redo lint`: run `actionlint`, `checkmake`, `hadolint`, `reuse`,
  `shellcheck`, `shfmt`, `typos`, `vale`, and `yamllint`.
- `redo test`: execute unit tests against the shells installed locally.
- `redo test-container`: run the test suite inside the supported container
  images.
- `./app/install`: install `lib/base.sh` into the expected local path.

Use `make test` only if you need the compatibility wrapper.

## Coding Style & Naming Conventions

Write shell as portable `sh` first. Keep Bash-specific features out unless the
file already depends on them. Follow the existing editor hints: 2-space
indentation, no tabs, and an approximately 79-character text width. Public
functions in `lib/base.sh` are unprefixed, internal helpers use `base_`, and
global variables use the `BASE_` prefix. Keep new test files aligned with the
current pattern, for example `app/test-realpath-ok`. Write comments in
third-person singular, and place a vertical gap before standalone comment lines
inside function bodies.

## Testing Guidelines

Add or update an executable script in `app/` for every behavior change. Use
`*-ok` for success cases and `*-no` for failure paths. Run `redo test` before
submitting; run `redo test-container` when changing portability-sensitive shell
logic, container files, or CI behavior. Keep tests deterministic and compatible
with multiple Unix-like shells.

## Commit & Pull Request Guidelines

Use Conventional Commits for all commits created by the agent, especially
scoped forms such as `build(deps): ...` and `chore(deps): ...`. Prefer concise,
imperative subjects with a meaningful scope when one exists. Pull requests
should explain the user-visible change, note any portability implications, and
confirm the relevant `redo lint` and `redo test` results. Link related issues
when applicable; UI screenshots are usually unnecessary for this repository.
