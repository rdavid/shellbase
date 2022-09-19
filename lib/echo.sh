# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2022 David Rabkin

# The function ‘repairs’ echo to behave in a reasonable way, see more:
#  http://www.etalabs.net/sh_tricks.html
echo() (
	fmt=%s
	end=\\n
	IFS=" "
	while [ $# -gt 1 ]; do
		case "$1" in
			[!-]*|-*[!ne]*)
				break
				;;
			*ne*|*en*)
				fmt=%b end=
				;;
			*n*)
				end=
				;;
			*e*)
				fmt=%b
				;;
		esac
	shift
	done
	# shellcheck disable=SC2059
	printf "$fmt$end" "$*"
)
