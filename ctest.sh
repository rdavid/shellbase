#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin
BASE_APP_VERSION=0.9.20220504

# shellcheck source=./inc/base
. "$(dirname "$(realpath "$0")")/inc/base"
validate_cmd podman
for f in container/*/Containerfile; do
	log "Test $(printf '%s' "$f" | awk --field-separator '/' '{print $2}')."

	# The build is ran quietly, it produces a container hash to run and remove.
	podman run \
		--interactive \
		--rm \
		--rmi \
		--tty \
		"$(podman build --file "$f" --quiet .)" \
		2>&1 | while IFS= read -r l; do log "$l"; done
done
exit 0
