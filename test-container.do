# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2022-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# Runs the lint and test targets inside every supported container image with
# Podman. The variable STP tracks whether the script started the Podman VM
# and should stop it on exit. Exit code 125 from podman machine start means
# the VM is already running or is still starting up. Command output streams
# to the console through the shellbase loggers, and the script prints OK to
# stdin for the redo target.
#
# Variable appears unused and file not following:
#  shellcheck disable=SC2034,SC1090
redo-ifchange \
	./app/* \
	./container/*/Containerfile \
	./lib/*
BSH="$(
	CDPATH='' cd -- "$(dirname -- "$0" 2>&1)" 2>&1 && pwd -P 2>&1
)"/lib/base.sh || {
	err=$?
	printf >&2 %s\\n "$BSH"
	exit $err
}
readonly \
	BASE_APP_VERSION=0.9.20260709 \
	BASE_MIN_VERSION=0.9.20260707 \
	BSH
. "$BSH"
STP=true
cmd_run podman machine start || {
	[ $? = 125 ] || die
	log Podman VM is already running.
	STP=false
}

# If tests run in shell-tracing mode, passes the tracing flag to the container.
inside "$-" x && EXE=-xx || EXE=''
inside "$(uname -m)" arm64 && ARM=true || ARM=false

# Builds the image silently and captures the container hash. Then runs the
# container and removes it automatically on exit.
for f in ./container/*/Containerfile; do
	[ "$ARM" = true ] && inside "$f" archlinux && {
		log Arch Linux does not currently support ARM architecture.
		continue
	}
	nme="$(printf %s "$f" | awk -F / '{print $3}' 2>&1)" || die "$nme"
	log "$nme..."
	chrono_sta run || die Unable to start timer.
	hsh="$(podman build --file "$f" --format docker --quiet . 2>&1)" ||
		die "$hsh"
	cmd_run podman run --rm --rmi "$hsh" "$EXE" lint test
	dur="$(chrono_sto run)" || die Unable to stop timer.
	log "$nme" "$dur".
done
[ "$STP" = false ] || podman machine stop
printf OK
