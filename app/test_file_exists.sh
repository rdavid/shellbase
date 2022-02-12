#!/bin/sh -eu
# vi:ts=2 sw=2 tw=79 et lbr wrap
# Copyright 2022 David Rabkin

# shellcheck source=../inc/base
. "$(dirname "$(realpath "$0")")/../inc/base"

file_exists /tmp && printf '/tmp exists.\n'
file_exists /tmp1 || printf '/tmp1 does not exist.\n'
file_exists /tmp/* && printf '/tmp/* exists\n.'
file_exists /tmp1/* || printf '/tmp1/* does not exist\n.'
exit 0
