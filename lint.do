# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2022-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
# Variable appears unused:
#  shellcheck disable=SC2034
readonly BASE_APP_VERSION=0.9.20260629
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
readonly BSH
set -- "$@" --quiet

# File not following:
#  shellcheck disable=SC1090
. "$BSH"
cmd_run_if actionlint
cmd_run_if checkmake ./Makefile
cmd_run_if hadolint ./container/*/Containerfile
cmd_run_if reuse lint
cmd_run_if shellcheck ./*.do ./app/* ./lib/*
cmd_run_if shfmt -d ./*.do ./app/* ./lib/*
cmd_run_if typos
cmd_exists vale && {
	vale sync >/dev/null 2>&1 || :
	vale ./README.adoc
}
cmd_run_if yamllint \
	./.github/*.yml \
	./.github/workflows/*.yml
cmd_run_if zizmor --offline ./.github/
./app/update
