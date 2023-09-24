# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022-2023 David Rabkin
redo-ifchange app/* lib/*

# shellcheck disable=SC1090,SC1091 # File not following.
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"/lib/base.sh
readonly SHELLS='ash bash dash fish ksh tcsh yash zsh'
for shell in $SHELLS; do
	cmd_exists "$shell" || continue
	for okey in app/*_okey; do
		"$shell" -c "$okey 2>&1"
	done
	for fail in app/*_fail; do
		"$shell" -c "$fail 2>&1 || :"
	done
done
