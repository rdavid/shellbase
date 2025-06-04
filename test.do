# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2022-2025 David Rabkin
# SPDX-License-Identifier: 0BSD
redo-ifchange app/* lib/*
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
	BASE_MIN_VERSION=0.9.20231228 \
	BSH
set -- "$@" --quiet

# shellcheck disable=SC1090 # File not following.
. "$BSH"
for sh in ash bash dash fish ksh oksh tcsh yash zsh; do
	cmd_exists "$sh" || continue
	chrono_sta run || die
	for ok in app/*-ok; do
		"$sh" -c "$ok 2>&1" || die "$ok" on "$sh" returns negative.
	done
	for no in app/*-no; do
		# shellcheck disable=SC2015 # A && B || C.
		"$sh" -c "$no 2>&1" && die "$no" on "$sh" returns positive. || :
	done
	dur="$(chrono_sto run)" || die
	printf >&2 '%4s %s.\n' "$sh" "$dur"
done
