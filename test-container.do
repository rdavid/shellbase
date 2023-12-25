# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022-2023 David Rabkin
redo-ifchange app/* lib/*
BSH="$(
	CDPATH='' cd -- "$(dirname -- "$0" 2>&1)" 2>&1 && pwd -P 2>&1
)"/lib/base.sh || {
	err=$?
	printf >&2 %s\\n "$BSH"
	exit $err
}

# shellcheck disable=SC2034 # Variable appears unused.
readonly \
	BASE_APP_VERSION=0.9.20231225 \
	BASE_MIN_VERSION=0.9.20231212 \
	BSH
set -- "$@" --quiet

# shellcheck disable=SC1090 # File not following.
. "$BSH"
validate_cmd podman
out="$(podman machine start 2>&1)" || {
	[ $? = 125 ] || die "$out"
	printf >&2 'VM already running or starting.\n'
}

# If the test is run in a mode of the shell where all executed commands are
# printed to the terminal, pass the mode further.
inside "$-" x && EXE=-xx || EXE=''

# The build is executed silently, resulting in a container hash. Runs a
# container and automatically removes it after it stops.
for f in container/*/Containerfile; do
	beg="$(date +%s 2>&1)" || die "$beg"
	hsh="$(podman build --file "$f" --quiet . 2>&1)" || die "$hsh"
	nme="$(printf %s "$f" | awk -F / '{print $2}' 2>&1)" || die "$nme"
	printf >&2 %s...\\n "$nme"
	podman run --rm "$hsh" "$EXE" lint test
	printf >&2 %s\ %s.\\n "$nme" "$(base_duration "$beg")"
done
