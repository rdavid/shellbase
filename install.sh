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
[ -w "$(dirname $TGT)" ] || die "$(dirname $TGT) is not writable."
cp -f "$BASE" $TGT || die "Unable to copy $BASE to $TGT."
printf \
	'shellbase %s is installed to %s.\n' \
	"$(sh $TGT --version)" \
	$TGT
exit 0
