#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin
set -- --quiet "$@"
BASE="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"/inc/base

# shellcheck source=./inc/base
. "$BASE"
DST=/usr/local/bin
TGT=$DST/shellbase
file_exists $DST || die $DST: No such directory.
is_writable $DST || die $DST is not writable.
if file_exists $TGT; then
	yes_to_continue \
		"$(sh $TGT --quiet --version)" \
		is already installed. Install \
		"$BASE_VERSION"?
fi
cp -f "$BASE" $TGT || die Unable to copy "$BASE" to $TGT.
printf \
	'%s is installed to %s.\n' \
	"$(sh $TGT --quiet --version)" \
	$DST
exit 0
