# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2022-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# Lints the project with whichever linters are installed, skipping the
# missing ones. Command output streams to the console through the shellbase
# loggers, while the script itself prints only OK to stdout, which redo
# captures as the target. Dash and mksh check syntax one file per
# invocation: a POSIX shell reads only its first operand as the script and
# hands any further operands to it as positional parameters, so files after
# the first would be silently skipped rather than checked.
#
# Variable appears unused and file not following:
#  shellcheck disable=SC2034,SC1090
redo-ifchange \
	./.github/*.yml \
	./.github/workflows/*.yml \
	./app/* \
	./container/*/Containerfile \
	./lib/* \
	./*.do \
	./Makefile \
	./README.adoc
BSH="$(
	CDPATH='' cd -- "$(dirname -- "$0" 2>&1)" 2>&1 && pwd -P 2>&1
)"/lib/base.sh || {
	err=$?
	printf >&2 %s\\n "$BSH"
	exit $err
}
readonly \
	BASE_APP_VERSION=0.9.20260711 \
	BASE_MIN_VERSION=0.9.20260707 \
	BSH
. "$BSH"
cmd_runif actionlint
cmd_runif checkmake ./Makefile
for f in ./*.do ./app/* ./lib/*; do
	cmd_runif dash -n "$f"
	cmd_runif mksh -n "$f"
done
cmd_runif hadolint ./container/*/Containerfile
cmd_runif reuse lint
cmd_runif shellcheck \
	./*.do \
	./app/* \
	./lib/*
cmd_runif shfmt -d \
	./*.do \
	./app/* \
	./lib/*
cmd_runif typos
cmd_runif vale sync
cmd_runif vale ./README.adoc
cmd_runif yamllint \
	./.github/*.yml \
	./.github/workflows/*.yml
cmd_runif zizmor --offline ./.github/
./app/update
printf OK
