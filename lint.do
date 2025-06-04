# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2022-2025 David Rabkin
# SPDX-License-Identifier: 0BSD
redo-ifchange \
	./*.do \
	.github/*.yml \
	.github/workflows/*.yml \
	app/* \
	container/*/Containerfile \
	lib/* \
	Makefile \
	README.adoc
BSH="$(
	CDPATH='' cd -- "$(dirname -- "$0" 2>&1)" 2>&1 && pwd -P 2>&1
)"/lib/base.sh || {
	err=$?
	printf >&2 %s\\n "$BSH"
	exit $err
}

# shellcheck disable=SC2034 # Variable appears unused.
readonly \
	BASE_APP_VERSION=0.9.20250604 \
	BASE_MIN_VERSION=0.9.20231212 \
	BSH
set -- "$@" --quiet

# shellcheck disable=SC1090 # File not following.
. "$BSH"
cmd_exists checkmake && checkmake Makefile
cmd_exists hadolint && hadolint container/*/Containerfile
cmd_exists reuse && reuse lint
cmd_exists shellcheck && shellcheck ./*.do app/* lib/*
cmd_exists shfmt && shfmt -d ./*.do app/* lib/*
cmd_exists typos && typos
cmd_exists vale && {
	vale sync >/dev/null 2>&1 || :
	vale README.adoc
}
cmd_exists yamllint && yamllint .github/*.yml .github/workflows/*.yml
./app/update
