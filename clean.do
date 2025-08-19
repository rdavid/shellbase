# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2023-2025 David Rabkin
# SPDX-License-Identifier: 0BSD
podman system prune --all --force && podman rmi --all --force
rm -f ./1 ./clean ./lint ./test ./test_container
