# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022-2023 David Rabkin
redo-ifchange app/* lib/*

# shellcheck disable=SC1090,SC1091 # File not following.
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"/lib/base.sh

# Redo logic requires redirection stderr to stdout.
for sh in ash bash dash fish ksh oksh tcsh yash zsh; do
	cmd_exists "$sh" 2>&1 || continue
	for ok in app/*-ok; do
		"$sh" -c "$ok 2>&1" || die "$ok" on "$sh" returns negative.
	done
	for no in app/*-no; do
		# shellcheck disable=SC2015 # A && B || C.
		"$sh" -c "$no 2>&1" && die "$no" on "$sh" returns positive. || :
	done
done
