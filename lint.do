# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022-2023 David Rabkin
redo-ifchange \
	./*.do \
	./*.md \
	.github/*.yml \
	.github/workflows/*.yml \
	app/* \
	container/*/Containerfile \
	lib/*

# shellcheck disable=SC1091 # File not following.
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"/lib/base.sh
cmd_exists checkmake && checkmake Makefile
cmd_exists hadolint && hadolint container/*/Containerfile
cmd_exists markdownlint && markdownlint ./*.md
cmd_exists shellcheck && shellcheck ./*.do app/* lib/*
cmd_exists shfmt && shfmt -d ./*.do app/* lib/*
cmd_exists yamllint && yamllint .github/*.yml .github/workflows/*.yml
