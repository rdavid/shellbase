# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022-2023 David Rabkin
redo-ifchange app/* lib/*

# shellcheck disable=SC1090,SC1091 # File not following.
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"/lib/base.sh
validate_cmd podman
podman machine start >/dev/null 2>&1 || :
for f in container/*/Containerfile; do
	log Test "$(printf %s "$f" | awk -F / '{print $2}')".

	# The build is ran quietly, it produces a container hash.
	out="$(podman build --file "$f" --quiet . 2>&1)" || die "$out"

	# Runs a container and automatically removes it after it stops.
	{
		podman run \
			--rm \
			--rmi \
			--tty \
			"$out" \
			2>&1 1>&3 3>&- | tologe
	} \
		3>&1 1>&2 | tolog
done
