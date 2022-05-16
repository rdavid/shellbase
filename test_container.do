# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin
redo-ifchange inc/* app/*

# shellcheck source=./inc/base
. "$(dirname "$(realpath "$0")")/inc/base"
validate_cmd podman
for f in container/*/Containerfile; do
	log "Test $(printf '%s' "$f" | awk --field-separator '/' '{print $2}')."

	# The build is ran quietly, it produces a container hash.
	out=$(podman build --file "$f" --quiet . 2>&1) || die "$out"

	# Run the container, then remove it.
	podman run \
		--interactive \
		--rm \
		--rmi \
		--tty \
		"$out" \
		2>&1 | while IFS= read -r l; do log "$l"; done
done
