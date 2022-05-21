#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin

# shellcheck source=./inc/base
BASE="$(dirname "$(realpath "$0")")/inc/base"
. "$BASE"
DEST=/usr/local/bin
TRGT=$DEST/shellbase
is_writable $DEST || die
if file_exists $TRGT; then
	printf \
		'%s is already installed. Install %s?\n' \
		"$(sh $TRGT --version)" \
		"$BASE_VERSION"
	yes_to_continue
fi
cp -f "$BASE" $TRGT || die "Unable to copy $BASE to $TRGT."
printf \
	'%s is installed to %s.\n' \
	"$(sh $TRGT --version)" \
	$DEST
exit 0
