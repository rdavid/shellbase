# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2022-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# Lints the project with any installed linters. Command output streams to
# the console through the shellbase loggers, and the script prints OK to
# stdin for the redo target.
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
	BASE_APP_VERSION=0.9.20260709 \
	BASE_MIN_VERSION=0.9.20260707 \
	BSH
. "$BSH"
cmd_runif actionlint
cmd_runif checkmake ./Makefile
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
