#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin

# shellcheck source=../inc/base
. "$(dirname "$(realpath "$0")")/../inc/base"

validate_cmd ls find grep
validate_cmd unknown
validate_cmd
exit 0
