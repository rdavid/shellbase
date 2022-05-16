#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin

# shellcheck source=./inc/base
BASE="$(dirname "$(realpath "$0")")/inc/base"
. "$BASE"
TGT=/usr/local/bin/shellbase
if [ -r "$TGT" ]; then
	printf \
		'%s is already installed. Install %s?\n' \
		"$(sh $TGT --version)" \
		"$BASE_VERSION"
	yes_to_continue
fi
[ -w "$(dirname $TGT)" ] || \
	{ printf '%s is not writable.\n' "$(dirname $TGT)" >&2; exit 11; }
cp -f "$BASE" $TGT || \
	{ printf 'Unable to copy %s to %s.\n' "$BASE" $TGT >&2; exit 12; }
printf \
	'shellbase %s is installed to %s.\n' \
	"$(sh $TGT --version)" \
	$TGT
exit 0
