#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2021-2022 David Rabkin

# shellcheck source=../inc/base
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"/../inc/base
touch /tmp/1 /tmp/2
chmod a-r /tmp/1
if is_readable /tmp/1 /tmp/2 /tmp; then
	ret=0
else
	ret=1
fi
rm /tmp/1 /tmp/2
exit $ret
