# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2023-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# Removes the redo targets and reclaims all Podman storage. Podman output
# streams to the console through stderr.
#
# A && B || C:
#  shellcheck disable=SC2015
command -v podman >/dev/null &&
	podman system prune --all --force >&2 &&
	podman rmi --all --force >&2 || :
rm -f ./1 ./clean ./lint ./test ./test-container
