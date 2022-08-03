#!/bin/sh -eu
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin

# shellcheck source=../inc/base
. "$(dirname "$(realpath "$0")")/../inc/base"

carbon=$(cat <<- EOM
	+-----------+----------+----------+
	|ID         |NAME      |TITLE     |
	+-----------+----------+----------+
	|123456789  |John Foo  |Director  |
	|12         |Mike Bar  |Engineer  |
	+-----------+----------+----------+
EOM
)

out="$(
	{
		printf 'ID\tNAME\tTITLE\n'
		printf '123456789\tJohn Foo\tDirector\n'
		printf '12\tMike Bar\tEngineer\n'
	} |
		prettytable |
		awk '{ print substr($0, index($0,$3)) }'
)"
[ "$carbon" = "$out" ]
exit 0
