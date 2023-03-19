# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022-2023 David Rabkin
redo-ifchange ./*.do app/* lib/*

# shellcheck disable=SC1091 # File not following.
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"/lib/base.sh
validate_cmd hadolint shellcheck shfmt yamllint
hadolint container/*/Containerfile
shellcheck ./*.do app/* lib/*
shfmt -d ./*.do app/* lib/*
yamllint .github/workflows/*
