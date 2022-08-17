#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin

# shellcheck source=../inc/base
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"/../inc/base
file_exists /tmp && printf '/tmp exists.\n'
file_exists /tmp1 || printf '/tmp1 does not exist.\n'
file_exists /tmp/* && printf '/tmp/* exists.\n'
file_exists /tmp1/* || printf '/tmp1/* does not exist.\n'
exit 0
