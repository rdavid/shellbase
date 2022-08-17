#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin

# shellcheck source=../inc/base
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"/../inc/base
foo() {
	i=1
	while [ $i -le 3 ]; do
		echo ---
		echo a
		echo a >&2
		echo b
		echo b >&2
		echo c
		echo c >&2
		echo d
		echo d >&2
		i=$(( i + 1 ))
		sleep 1
	done
}

{
	foo \
	2>&1 1>&3 3>&- | to_loge
} \
	3>&1 1>&2 | to_log
exit 0
