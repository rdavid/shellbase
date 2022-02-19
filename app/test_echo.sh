#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin

# shellcheck disable=SC1091
. "$(dirname "$(realpath "$0")")/../inc/base"
. "$(dirname "$(realpath "$0")")/../inc/echo"

echo hello
# shellcheck disable=SC3037
echo "-e"
# shellcheck disable=SC2028
echo "\\n"
# shellcheck disable=SC3037
echo -n hello
# shellcheck disable=SC3037
echo -ne hello
echo bye
exit 0
