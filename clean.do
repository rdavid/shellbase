# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2023-2024 David Rabkin
podman system prune --all --force && podman rmi --all --force
rm -f 1 clean lint test test_container
