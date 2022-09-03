# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin
set -o errexit
set -o nounset
redo-ifchange lib/* app/*

# shellcheck disable=SC1091
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"/lib/base.sh
readonly SHELLS='bash dash fish ksh sh tcsh zsh'
for shell in $SHELLS; do
	cmd_exists "$shell" || continue
	for okey in app/*_okey; do
		"$shell" -c "$okey 2>&1"
	done
	for fail in app/*_fail; do
		"$shell" -c "$fail 2>&1 || :"
	done
done
