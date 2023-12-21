# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022-2023 David Rabkin
# shellcheck disable=SC2039,SC3043 # Uses local variables.
redo-ifchange app/* lib/*
set -- "$@" --quiet
BSH="$(
	CDPATH='' cd -- "$(dirname -- "$0" 2>&1)" 2>&1 && pwd -P 2>&1
)"/lib/base.sh || {
	local err=$?
	printf >&2 %s\\n "$BSH"
	exit $err
}

# shellcheck disable=SC2034 # Variable appears unused.
readonly \
	BASE_APP_VERSION=0.9.20231221 \
	BASE_MIN_VERSION=0.9.20231212 \
	BSH

# shellcheck disable=SC1090 # File not following.
. "$BSH"
validate_cmd podman
out="$(podman machine start 2>&1)" || {
	[ $? = 125 ] || die "$out"
	log VM already running or starting.
}
for f in container/*/Containerfile; do
	log Test "$(printf %s "$f" | awk -F / '{print $2}')".

	# The build is executed silently, resulting in a container hash.
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
