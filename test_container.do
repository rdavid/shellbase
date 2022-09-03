# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin
set -o errexit
set -o nounset
redo-ifchange lib/* app/*

# shellcheck disable=SC1091
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"/lib/base.sh
validate_cmd podman
podman machine start >/dev/null 2>&1 || :
for f in container/*/Containerfile; do
	log "Test $(printf %s "$f" | awk -F / '{print $2}')."

	# The build is ran quietly, it produces a container hash.
	out=$(podman build --file "$f" --quiet . 2>&1) || die "$out"

	# Run the container, then remove it.
	{
		podman run \
			--interactive \
			--rm \
			--rmi \
			--tty \
			"$out" \
		2>&1 1>&3 3>&- | to_loge
	} \
		3>&1 1>&2 | to_log
done
