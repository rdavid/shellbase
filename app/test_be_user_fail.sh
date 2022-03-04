#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2021-2022 David Rabkin

# shellcheck source=../inc/base
. "$(dirname "$(realpath "$0")")/../inc/base"

be_user n0t_ex1sted_uzer
exit 0
