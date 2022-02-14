#!/bin/sh -eu
# vi:ts=2 sw=2 tw=79 et lbr wrap
# Copyright 2022 David Rabkin

# shellcheck source=../inc/base
. "$(dirname "$(realpath "$0")")/../inc/base"

mkdir /tmp/empty-dir
is_empty /tmp || printf '/tmp is not empty.\n'
is_empty /tmp/empty-dir && printf '/tmp/empty-dir is empty.\n'
rmdir /tmp/empty-dir
exit 0
