#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2021-2022 David Rabkin

# shellcheck source=../inc/base
. "$(dirname "$(realpath "$0")")/../inc/base"

i=1
while [ "$i" -ne 10 ]; do
	printf "%s\n" "$(base_duration 0)"
	i=$((i+1))
	sleep 1
done
