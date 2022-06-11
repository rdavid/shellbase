#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin
set -- --quiet "$@"
BASE="$(dirname "$(realpath "$0")")/inc/base"

# shellcheck source=./inc/base
. "$BASE"
DST=/usr/local/bin
TGT=$DST/shellbase
file_exists $DST || die $DST: No such directory.
is_writable $DST || die $DST is not writable.
if file_exists $TGT; then
	printf \
		'%s is already installed. Install %s?\n' \
		"$(sh $TGT --quiet --version)" \
		"$BASE_VERSION"
	yes_to_continue
fi
cp -f "$BASE" $TGT || die "Unable to copy $BASE to $TGT."
printf \
	'%s is installed to %s.\n' \
	"$(sh $TGT --quiet --version)" \
	$DST
exit 0
