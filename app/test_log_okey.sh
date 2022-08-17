#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin

# shellcheck source=../inc/base
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"/../inc/base
i=0
while [ $i -ne 10 ]; do
	case "$((i%3))" in
		0) log "$i" ;;
		1) logw "$i" ;;
		2) loge "$i" ;;
	esac
	i="$((i+1))"
done
exit 0
