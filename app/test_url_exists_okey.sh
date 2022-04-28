#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin

# shellcheck source=../inc/base
. "$(dirname "$(realpath "$0")")/../inc/base"

url_exists http://google.com && printf 'http://google.com exists.\n'
url_exists http://google.com1 || printf 'http://google.com1 does not exist.\n'
url_exists 1.1.1.1 && printf '1.1.1.1 exists.\n'
url_exists 1.1.1.256 || printf '1.1.1.256 does not exist.\n'
exit 0
