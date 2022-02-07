#!/bin/sh -eu
# vi:ts=2 sw=2 tw=79 et lbr wrap
# Copyright 2021-2022 David Rabkin

# shellcheck source=../inc/base
. "$(dirname "$(realpath "$0")")/../inc/base"

DUR=2
printf 'Sleeping for %s seconds...\n' $DUR
sleep $DUR
exit 0
