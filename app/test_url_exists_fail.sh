#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin

# shellcheck source=../inc/base
. "$(dirname "$(realpath "$0")")/../inc/base"

url_exists \
	http://google.com/ \
	1.1.1.1 \
	http://doesnotexist.c0m/
exit 0
