#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin

# shellcheck source=../inc/base
. "$(dirname "$(realpath "$0")")/../inc/base"

yes_to_continue
printf Continued\ first.\\n
yes_to_continue You\'re "$USER", continue?
printf Continued\ second.\\n
exit 0
