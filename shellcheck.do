# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022-2023 David Rabkin
set -- --quiet "$@"
redo-ifchange app/* lib/*

# shellcheck disable=SC1091 # File not following.
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"/lib/base.sh
validate_cmd shellcheck
shellcheck app/* lib/*
