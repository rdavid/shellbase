#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2021-2022 David Rabkin

# shellcheck source=../inc/base
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"/../inc/base
be_user "$USER"
printf 'You are %s.\n' "$USER"
exit 0
