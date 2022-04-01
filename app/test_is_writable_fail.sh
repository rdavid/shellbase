#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2021-2022 David Rabkin

# shellcheck source=../inc/base
. "$(dirname "$(realpath "$0")")/../inc/base"

touch /tmp/1 /tmp/2
chmod -w /tmp/1
if is_writable /tmp/1 /tmp/2 /tmp/3; then
	ret=0
else
	ret=1
fi
chmod +w /tmp/1
rm /tmp/1 /tmp/2
exit $ret
