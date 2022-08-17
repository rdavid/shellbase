#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2021-2022 David Rabkin

# shellcheck source=../inc/base
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"/../inc/base
touch /tmp/1 /tmp/2
is_readable /tmp/1 /tmp/2 /tmp
rm /tmp/1 /tmp/2
exit 0
