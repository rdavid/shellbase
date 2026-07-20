# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2022-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# Runs every executable test case under app/ against each locally installed
# shell. Test output streams to the console through stderr, and the script
# prints OK to stdout for the redo target.
#
# Variable appears unused, file not following and A && B || C:
#  shellcheck disable=SC2034,SC1090,SC2015
redo-ifchange ./app/* ./lib/*
BSH="$(
	CDPATH='' cd -- "$(dirname -- "$0" 2>&1)" 2>&1 && pwd -P 2>&1
)"/lib/base.sh || {
	err=$?
	printf >&2 %s\\n "$BSH"
	exit $err
}
readonly \
	BASE_APP_VERSION=0.9.20260720 \
	BASE_MIN_VERSION=0.9.20231228 \
	BSH
. "$BSH"
for sh in ash bash dash fish ksh oksh tcsh yash zsh; do
	cmd_exists "$sh" || continue
	chrono_sta run || die
	for ok in ./app/*-ok; do
		"$sh" -c "$ok 2>&1" >&2 || die "$ok" on "$sh" returns negative.
	done
	for no in ./app/*-no; do
		"$sh" -c "$no 2>&1" >&2 && die "$no" on "$sh" returns positive. || :
	done
	dur="$(chrono_sto run)" || die
	log "$sh" "$dur."
done
printf OK
