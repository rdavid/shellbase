# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2020-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# The shellbase framework serves as a foundation for Unix shell scripts. It
# mostly follows POSIX, the Portable Operating System Interface standard, and
# runs across Unix-like systems. The framework offers essential services,
# including logging, validation helpers, signal handling, garbage collection,
# and support for concurrent instances.
#
# The framework defines global variables and functions. Functions without the
# base_ prefix are public, and clients may call them. The public functions
# are, in alphabetical order:
# aud_only, beroot, beuser, bomb, cheat, chrono_get, chrono_sta, chrono_sto,
# cmd_exists, cmd_run, cmd_runif, cya, die, dng2jpg, echo, ellipsize,
# file_exists, gitlog, grbt, handle_pipefails, heic2jpg, inside, isempty,
# isfunc, isnumber, isreadable, isroot, issolid, iswritable, log, loge, logw,
# map_del, map_get, map_put, nmea2gpx, pdf2jpg, pdf2png, prettytable,
# prettyuptime, realdir, realpath, retry, semver, should_continue, timestamp,
# tolog, tologe, tolower, totsout, tsout, url_exists, user_exists,
# validate_cmd, validate_var, var_exists, ver_ge, vid2aud, ytda.
#
# Global variables carry the BASE_ prefix. Clients may use them and should
# place temporary files under $BASE_WIP. Functions with the base_ prefix stay
# internal, and clients shouldn't call them. All names appear in alphabetical
# order.
#
# Command line parameters may change the following variables. They become
# readonly after the parsing of the command line. BASE_RC_... and BASE_VERSION
# stay writable to survive double sourcing in interactive mode. A better
# solution may exist.
#
# The script uses local variables, which POSIX omits but most shells support.
# See:
#  https://stackoverflow.com/q/18597697
#  shellcheck disable=SC2039,SC3043
BASE_DIR_WIP=/tmp
BASE_FORK_CNT=0
BASE_KEEP_WIP=false
BASE_LOG_CAP=$((10 * 1024 * 1024))
BASE_QUIET=false
BASE_RC_ARG_NE=15
BASE_RC_ARG_NO=11
BASE_RC_ARG_WA=12
BASE_RC_CMD_NE=16
BASE_RC_CON_NO=14
BASE_RC_CON_TO=13
BASE_RC_DIE_NO=10
BASE_RC_VAR_NE=17
BASE_SHOULD_CON=false
BASE_VERSION=0.9.20260716

# Removes any file besides mp3, m4a, flac in the current directory, then
# removes empty directories if they exist. xargs handles white spaces while
# counting the matched files. The confirmation message is deliberately not
# indented: leading tabs would appear verbatim in the prompt.
aud_only() {
	local cnt err lst msg
	lst=$(
		find . -type f \
			! \( \
			-name '*.[Mm][Pp]3' -o \
			-name '*.[Mm]4[Aa]' -o \
			-name '*.[Ff][Ll][Aa][Cc]' \
			\) 2>&1
	) || {
		err=$?
		loge "$lst"
		return $err
	}
	[ -z "$lst" ] && {
		log Nothing to remove.
		return 0
	}
	cnt="$(printf %s\\n "$lst" | wc -l | xargs)" || {
		err=$?
		loge Something went wrong.
		return $err
	}
	msg="Remove the following files:
$lst
Total $cnt files"
	should_continue "$msg" || return
	log Removing "$cnt" files.
	cmd_run find . -type f \
		! \( \
		-name '*.[Mm][Pp]3' -o \
		-name '*.[Mm]4[Aa]' -o \
		-name '*.[Ff][Ll][Aa][Cc]' \
		\) \
		-exec rm -f {} + || return
	cmd_run find . -type d -empty -delete
}

# Checks if the script is run by the root user.
beroot() {
	beuser root
}

# Checks if the script is run by a user.
beuser() {
	cmd_exists id || return
	local ask cur usr="$1"
	user_exists "$usr" || die "$usr": No such user.
	cur="$(id -u 2>&1)" || die "$cur"
	ask="$(id -u "$usr" 2>&1)" || die "$ask"
	[ "$ask" -eq "$cur" ] || die "You are $(id -un) ($cur), be $usr ($ask)."
	log "You are $usr ($cur)."
}

# Requests permission to execute the fork bomb.
bomb() {
	should_continue 'Throw the fork bomb' || return
	base_bomb
}

# The only cheat sheet you need.
cheat() {
	cmd_exists curl || return
	curl https://cht.sh/"$1"
}

# Calculates a duration from the start. There are 86400 seconds in a day,
# 3600 in an hour, and 60 in a minute.
chrono_get() {
	local \
		beg \
		err \
		day \
		dur \
		hou \
		min \
		nme="$1" \
		now \
		sec
	now="$(date +%s 2>&1)" || {
		err=$?
		loge "$now"
		return $err
	}
	beg="$(map_get "$nme" sta)" || return
	dur="$((now - beg))"
	day="$(base_time_title $((dur / 86400)) day)"
	hou="$(base_time_title $((dur % 86400 / 3600)) hour)"
	min="$(base_time_title $((dur % 86400 % 3600 / 60)) minute)"
	sec="$(base_time_title $((dur % 60)) second)"
	if [ -n "$day" ]; then
		printf %s "$day" "$(base_time_separator "$hou" "$min" "$sec")"
	fi
	if [ -n "$hou" ]; then
		printf %s "$hou" "$(base_time_separator "$min" "$sec")"
	fi
	if [ -n "$min" ]; then
		printf %s "$min" "$(base_time_separator "$sec")"
	fi
	if [ -n "$sec" ]; then
		printf %s "$sec"
	fi
	if [ -z "$day" ] && [ -z "$hou" ] && [ -z "$min" ] && [ -z "$sec" ]; then
		printf 'less than a second'
	fi
}

# Marks the beginning of a period. The only parameter is the stopwatch name.
chrono_sta() {
	local err nme="$1" now
	now="$(date +%s 2>&1)" || {
		err=$?
		loge "$now"
		return $err
	}
	map_put "$nme" sta "$now"
}

# Calculates a duration from the start and cleans inner data.
chrono_sto() {
	local dur nme="$1"
	dur="$(chrono_get "$nme")" || return
	map_del "$nme" sta || return
	printf %s "$dur"
}

# Checks that every argument names a command that exists and is executable.
# Finding a command is the common case and stays silent; a missing one is
# warned unless -q is set. With no arguments it fails with BASE_RC_ARG_NO.
# Return code:
#  - 0 when all commands are present;
#  - otherwise a count of the missing commands that starts from BASE_RC_CMD_NE:
#    one missing yields BASE_RC_CMD_NE, each further miss adds one, capped so
#    the result stays within the shell's 0..255 return range.
# Usage: cmd_exists [-q] cmd1 [cmd2 ...]
# Options: -q (quiet mode - suppress warnings and errors)
cmd_exists() {
	local cmd cnt=0 max=$((256 - BASE_RC_CMD_NE)) qui=false
	[ "${1-}" = -q ] && {
		qui=true
		shift
	}
	[ $# -eq 0 ] && {
		[ "$qui" = false ] && loge No commands specified to check.
		return $BASE_RC_ARG_NO
	}
	for cmd; do
		command -v "$cmd" >/dev/null 2>&1 || {
			[ "$qui" = false ] && logw "Command $cmd not found."
			cnt=$((cnt + 1))
			[ "$cnt" -lt "$max" ] || {
				[ "$qui" = false ] && logw "Missing command count is capped at $max."
				break
			}
		}
	done
	[ "$cnt" -eq 0 ] || return $((BASE_RC_CMD_NE + cnt - 1))
}

# Runs a command after confirming it exists. Without -q it logs the command,
# streams its output through the loggers, and reports a non-zero exit as an
# error; -q runs it silently, discarding output and skipping both logs. Returns
# the cmd_exists code when the command is absent or unspecified, otherwise the
# command's own code.
# Usage: cmd_run [-q] cmd [arg ...]
# Options: -q (quiet mode - suppress logs and warnings)
# Streaming splits the command across both loggers: 2>&1 1>&3 sends stderr to
# tologe and stdout, via fd 3, to tolog. A pipeline reports only its last stage
# and pipefail is optional, so the exit code cannot ride the pipes; exec 4>&1
# aliases fd 4 to the command substitution's stdout and printf writes the code
# there, past the pipes, for err to capture.
# $opt and ${1-} stay unquoted so an absent flag or command drops out:
#  shellcheck disable=SC2086,SC2069
cmd_run() {
	local err opt=
	[ "${1-}" = -q ] && {
		opt=-q
		shift
	}
	cmd_exists $opt ${1-} || return
	[ -n "$opt" ] && {
		"$@" >/dev/null 2>&1
		return
	}
	log "» $*"
	err=$(
		exec 4>&1
		{
			{
				if "$@" 2>&1 1>&3 3>&-; then
					printf %s 0 >&4
				else
					printf %s "$?" >&4
				fi
			} | tologe
		} 3>&1 1>&2 | tolog
	) || :
	[ "$err" -eq 0 ] && return 0
	loge "$1 failed, err=$err."
	return "$err"
}

# Like cmd_run for optional tools: a missing command becomes a skipped no-op
# returning 0 while every other outcome keeps cmd_run's own code. It runs the
# command through cmd_run and remaps only BASE_RC_CMD_NE to 0, so a real
# failure, or an unspecified command failing with BASE_RC_ARG_NO, still
# propagates. A command that itself exits with BASE_RC_CMD_NE cannot be told
# apart from a missing one and also counts as skipped. Both $? expansions
# occur while $? still holds cmd_run's code, so the remap is exact.
# Usage: cmd_runif [-q] cmd [arg ...]
# Options: -q (quiet mode - suppress logs and warnings)
cmd_runif() {
	cmd_run "$@" || return $(($? == BASE_RC_CMD_NE ? 0 : $?))
}

# Prints all parameters to the log and exits with a success code. The subshell
# restores $? for base_exit, which reads it. The err value may be zero.
# oh-my-zsh has the lol plugin, which defines an alias to cya. Remove the
# plugin:
#  https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/lol
cya() {
	local err=$?
	[ $# = 0 ] || log "$@"
	(exit $err)
	base_exit
}

# Prints all parameters as an error message and exits with the error code. It
# attempts to retain the original code. Otherwise it uses BASE_RC_DIE_NO, so
# err is always non-empty.
die() {
	local err=$?
	[ $# = 0 ] || loge "$@"
	[ $err -ne 0 ] || err=$BASE_RC_DIE_NO
	(exit $err) || base_exit
}

# Converts DNG files in the current directory to JPEG.
dng2jpg() {
	base_img2jpg '*.[dD][nN][gG]'
}

# Portable echo that handles -n, -e, and -ne consistently, unlike the built-in
# whose flag handling varies between shells. See:
#  http://www.etalabs.net/sh_tricks.html
# Uses variables in the printf format string:
#  shellcheck disable=SC2059
echo() {
	local end=\\n fmt=%s IFS=' '
	while [ $# -gt 1 ]; do
		case "$1" in
		[!-]* | -*[!ne]*) break ;;
		*ne* | *en*) fmt=%b end= ;;
		*n*) end= ;;
		*e*) fmt=%b ;;
		esac
		shift
	done
	printf "$fmt$end" "$*"
}

# Truncates a string to specified maximum length, inserting ellipsis in the
# middle if necessary. The resulting string will never be longer than the
# specified maximum length. The original string is returned if it is already
# shorter than or equal to the maximum length.
# The origin of the idea:
#  https://github.com/yegor256/ellipsized
ellipsize() {
	local beg end max="$2" str="$1"
	[ $# -eq 2 ] || {
		loge ellipsize: expected 2 arguments, got "$#".
		return $BASE_RC_ARG_NO
	}
	isnumber "$max" || {
		loge ellipsize: max is not numeric: "$max".
		return $BASE_RC_ARG_NO
	}
	cmd_exists awk || return
	[ "${#str}" -le "$max" ] && {
		printf %s "$str"
		return
	}
	beg=$(((max - 3) / 2))
	end=$beg
	[ $((beg + end + 3)) -lt "$max" ] && beg=$((beg + 1))
	[ "$beg" -gt "$max" ] && beg=$max
	awk \
		-v b="$beg" \
		-v e="$end" \
		-v s="$str" \
		'BEGIN {
			n = length(s)
			p = (b > 0) ? substr(s, 1, b) : ""
			q = (e > 0) ? substr(s, n - e + 1) : ""
			printf "%s...%s", p, q
		}'
}

# Verifies the existence of all files. Iterates through the arguments,
# with each argument representing a file name. Fails if any of the specified
# files do not exist.
file_exists() {
	local arg
	[ $# -gt 0 ] || return $BASE_RC_ARG_NO
	for arg; do
		[ -e "$arg" ] || [ -L "$arg" ] || return $BASE_RC_ARG_NE
	done
}

# Allows users to navigate the history of commits in a Git repository.
gitlog() {
	cmd_exists fzf git grep head less xargs || return
	git log \
		--color=always \
		--format="%C(auto)%h%d %s %C(black)%C(bold)%cr" \
		--graph \
		"$@" |
		fzf \
			--ansi \
			--bind=ctrl-s:toggle-sort \
			--no-sort \
			--reverse \
			--tiebreak=index \
			--bind "ctrl-m:execute:
			(
				grep -o '[a-f0-9]\{7\}' |
				head -1 |
				xargs -I % sh -c 'git show --color=always % | less -R'
			) << FZF-EOF
			{}
FZF-EOF"
}

# Generates a temporary commit, performs a rebase, and pushes the changes.
grbt() {
	cmd_exists git || return
	local br
	br="$(git rev-parse --abbrev-ref HEAD 2>&1)" || die "$br"
	git commit --all --message tmp &&
		git push &&
		git rebase --interactive HEAD~5 &&
		git push origin +"$br"
}

# Ignores exit code 141 (128 + SIGPIPE) from command pipes. See:
#  https://stackoverflow.com/q/22464786
handle_pipefails() {
	local err=141
	[ "$1" -eq "$err" ] || return "$1"
	log Ignore the pipe failure with the error code "$err".
}

# Converts HEIC files in the current directory to JPEG.
heic2jpg() {
	base_img2jpg '*.[hH][eE][iI][cC]'
}

# Returns true if $2 is inside $1. Uses a case statement because it is a shell
# built-in and faster than grep:
#  echo $1 | grep -s "$2" >/dev/null
# or this:
#  echo $1 | grep -qs "$2"
# or expr:
#  expr "$1" : ".*$2" >/dev/null && return 0 # true
# Case does not require another shell process. See:
#  https://www.grymoire.com/Unix/Sh.html#toc-uh-96
inside() {
	case "$1" in *$2*) return 0 ;; esac
	return 1
}

# Determines whether a directory is empty. See:
#  https://unix.stackexchange.com/q/202243
isempty() {
	cd "$1" >/dev/null 2>&1 || {
		local err=$?
		loge The directory is not accessible: "$1", err=$err.
		return $err
	}
	local ret
	set +o nounset -- ./* ./.[!.]* ./..?*
	if [ -n "$4" ] ||
		for e; do
			[ -L "$e" ] ||
				[ -e "$e" ] && break
		done; then
		ret=1
	else
		ret=0
	fi
	set -o nounset
	cd "$OLDPWD"
	return $ret
}

# Determines whether a shell function with a given name exists. See:
#  https://stackoverflow.com/q/35818555
isfunc() {
	local str
	str="$(type "$1" 2>&1)" || {
		local err=$?
		loge "$str"
		return $err
	}
	inside "$str" function
}

# Determines whether a variable is a number. This rejects empty strings and
# strings containing non-digits while accepting everything else. See:
#  https://stackoverflow.com/q/806906
isnumber() {
	case "$1" in
	'' | *[!0-9]*) return 1 ;;
	esac
	return 0
}

# Verifies that all parameters are readable files.
isreadable() {
	local arg
	for arg; do
		[ -r "$arg" ] || return 1
	done
}

# Checks if the current user is root. Uses `id -u` to get the numeric UID.
# Returns success (0) if UID == 0 (root), otherwise failure (1).
isroot() {
	local err num
	num="$(id -u 2>&1)" || {
		err=$?
		loge "$num"
		return $err
	}
	[ "$num" -eq 0 ]
}

# Verifies that the running script's content matches the script hash (SHA-1, as
# computed by shasum). It ignores the line where the hash is defined.
issolid() {
	cmd_exists awk head grep shasum || return
	local \
		err \
		fle="$0" \
		hsh \
		lne \
		tmp="$BASE_WIP"/hashless \
		pat=^BASE_APP_HASH
	isreadable "$fle" || die File "$fle" is not readable.
	lne="$(
		grep --regexp "$pat" "$fle"
	)" || {
		err=$?
		loge File "$fle" doesn\'t have a hash.
		return $err
	}
	hsh="$(
		printf %s "$lne" | head -1 | awk -F = '{print $2}'
	)" || {
		err=$?
		loge File "$fle" has hash with unknown format: "$lne".
		return $err
	}
	grep --invert-match --regexp "$pat" "$fle" >"$tmp"
	printf %s\ \ %s "$hsh" "$tmp" | shasum --check --status || {
		err=$?
		loge Hash of "$fle" does not match "$hsh"
		return $err
	}
	log File "$fle" is solid.
}

# Verifies that all parameters are writable files or do not exist.
iswritable() {
	local arg
	for arg; do
		if file_exists "$arg"; then
			[ -w "$arg" ] || return 1
		else
			touch "$arg" 2>/dev/null || return
			rm "$arg"
		fi
	done
}

# Sends all log messages to stderr. The information logger is silent with the
# --quiet flag.
log() {
	local tms
	tms="$(timestamp)" || exit $?
	[ "$BASE_QUIET" = false ] &&
		printf >&2 '%s%s%s %s\n' "$BASE_FMT_GREEN" "$tms" "$BASE_FMT_RESET" "$*"
	base_is_interactive || base_write_to_file "$tms" i "$*"
}

# Error logger always prints to stderr.
loge() {
	local tms
	tms="$(timestamp)" || exit $?
	printf >&2 '%s%s%s %s\n' "$BASE_FMT_RED" "$tms" "$BASE_FMT_RESET" "$*"
	base_is_interactive || base_write_to_file "$tms" e "$*"
}

# The warning logger is silent with the --quiet flag.
logw() {
	local tms
	tms="$(timestamp)" || exit $?
	[ "$BASE_QUIET" = false ] &&
		printf >&2 '%s%s%s %s\n' "$BASE_FMT_YELLOW" "$tms" "$BASE_FMT_RESET" "$*"
	base_is_interactive || base_write_to_file "$tms" w "$*"
}

# Deletes from key-value store.
map_del() {
	local \
		dir="$BASE_WIP"/map \
		err \
		key="$2" \
		nme="$1"
	local fle="$dir/$nme/$key"
	file_exists "$fle" || {
		err=$?
		loge "$fle": No such file.
		return $err
	}
	rm "$fle"
	isempty "$dir/$nme" || return 0
	rmdir "$dir/$nme"
	isempty "$dir" || return 0
	rmdir "$dir"
}

# Reads from key-value store.
map_get() {
	local \
		dir="$BASE_WIP"/map \
		err \
		key="$2" \
		nme="$1" \
		val
	local fle="$dir/$nme/$key"
	isreadable "$fle" || {
		err=$?
		loge Unable to read "$fle".
		return $err
	}
	val="$(cat "$fle" 2>&1)" || {
		err=$?
		loge "$val"
		return $err
	}
	printf %s "$val"
}

# Adds to key-value store.
map_put() {
	local \
		dir="$BASE_WIP"/map \
		key="$2" \
		nme="$1" \
		val="$3"
	[ -d "$dir" ] || mkdir "$dir"
	[ -d "$dir/$nme" ] || mkdir "$dir/$nme"
	printf %s "$val" >"$dir/$nme/$key"
}

# Converts all .log files in the current directory to .gpx files using
# gpsbabel, skipping unmatched glob literals and dangling links. gpsbabel may
# reject long option names, so the call uses short options.
nmea2gpx() {
	local fle out
	cmd_exists gpsbabel || return
	for fle in ./*.log; do
		[ -e "$fle" ] || [ -L "$fle" ] || continue
		out="${fle%.log}.gpx"
		log "Converting $fle to $out."
		gpsbabel \
			-i nmea \
			-f "$fle" \
			-o gpx \
			-F "$out" || return
	done
}

# Converts all PDF files in current directory to JPEG files.
pdf2jpg() {
	base_pdf2img -jpeg
}

# Converts all PDF files in current directory to PNG files.
pdf2png() {
	base_pdf2img -png
}

# Draws an ASCII table with sized columns. Columns are tab-separated. Expects
# input as:
# {
# 	printf 'ID\tNAME\tTITLE\n'
# 	printf '123456789\tJohn Foo\tDirector\n'
# 	printf '12\tMike Bar\tEngineer\n'
# } | prettytable
# It produces output:
# +-----------+----------+----------+
# |ID         |NAME      |TITLE     |
# +-----------+----------+----------+
# |123456789  |John Foo  |Director  |
# |12         |Mike Bar  |Engineer  |
# +-----------+----------+----------+
# The sed script needs double quotes for its escaped last-line address. The
# implementation is inspired by Jakob Westhoff:
#  https://github.com/jakobwesthoff/prettytable.sh
prettytable() {
	cmd_exists column sed || return
	local bdy col hdr inp
	inp="$(cat)"
	hdr="$(printf %s "$inp" | head -n1)" || handle_pipefails $?
	bdy="$(printf %s "$inp" | tail -n+2)" || handle_pipefails $?
	col="$(printf %s "$hdr" | awk -F\\t '{print NF}')"
	{
		base_prettytable_separator "$col"
		printf %s\\n "$hdr" | base_prettytable_prettify
		base_prettytable_separator "$col"
		printf %s\\n "$bdy" | base_prettytable_prettify
		base_prettytable_separator "$col"
	} |
		column -ts '	' |
		sed "1s/ /-/g;3s/ /-/g;\$s/ /-/g"
}

# Displays uptime in a human-readable format. See:
#  https://stackoverflow.com/q/28353409
prettyuptime() {
	cmd_exists sed tr uptime || {
		local err=$?
		printf '↑ err=%d' "$err"
		return $err
	}
	uptime | sed -E '
		s/^[^,]*up *//
		s/mins/minutes/
		s/hrs?/hours/
		s/([[:digit:]]+):0?([[:digit:]]+)/\1 hours, \2 minutes/
		s/^1 hours/1 hour/
		s/ 1 hours/ 1 hour/
		s/min,/minutes,/
		s/ 0 minutes,/ less than a minute,/
		s/ 1 minutes/ 1 minute/
		s/  / /
		s/, *[[:digit:]]* users?.*//
		s/^/↑ /
	' | tr -d \\n
}

# Returns the absolute directory of a file. See the description of realpath.
realdir() {
	local dir str="$1"
	dir="$(dirname -- "$str" 2>&1)" || die "$dir"
	dir="$(CDPATH='' \cd -- "$dir" 2>&1 && pwd -P)" || die "$dir"
	printf %s "$dir"
}

# Returns absolute path to a file. See:
#  https://stackoverflow.com/q/3915040
realpath() {
	local dir nme str="$1"
	dir="$(realdir "$str")" || die
	nme="$(basename -- "$str" 2>&1)" || die "$nme"
	[ / = "$dir" ] && printf /%s "$nme" || printf %s/%s "$dir" "$nme"
}

# Runs a command up to max attempts (-n num, default 5) with exponential
# backoff (1 s, 2 s, 4 s, ...), skipping the wait after the last attempt. Logs
# each attempt and exit code, plus a final error if all are exhausted.
# Usage: retry [-n num] cmd [arg ...]
retry() {
	local cnt=1 dly=1 err max=5
	[ "${1-}" = -n ] && {
		[ -n "${2-}" ] || {
			loge No count specified for -n.
			return $BASE_RC_ARG_NO
		}
		[ "$2" -ge 1 ] 2>/dev/null || {
			loge Invalid -n count="$2", needs a positive integer.
			return $BASE_RC_ARG_NO
		}
		max="$2"
		shift 2
	}
	[ $# -gt 0 ] || {
		loge No command specified to retry.
		return $BASE_RC_ARG_NO
	}
	while [ "$cnt" -le "$max" ]; do
		log Retry "$cnt"/"$max": "$@"
		"$@" && return 0
		err=$?
		logw Retry "$cnt" failed, err="$err".
		[ "$cnt" -lt "$max" ] && {
			log Sleeping "$dly"s before next retry.
			sleep "$dly"
		}
		dly=$((dly * 2))
		cnt=$((cnt + 1))
	done
	loge All "$max" retries exhausted.
	return $err
}

# Extracts semantic versioning from a string. See:
#  https://semver.org
#  1.2.3
#  1.2.3+meta
#  1.2.3-4-alpha
# Uses GNU grep with PCRE option.
semver() {
	local ret=0 str="$1" ver
	ver="$(
		printf %s "$str" |
			grep --only-matching --perl-regexp \
				'(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$' 2>&1
	)" || {
		ret=$?
		loge "$ver"
		ver=0.0.0+nil
	}
	printf %s "$ver"
	return $ret
}

# Asks for permission to continue. Returns an error code if the input is not
# 'y' or if no input is detected after a timeout. If parameters are provided,
# they are used as the question. Otherwise, the default message is used.
should_continue() {
	[ $BASE_SHOULD_CON = true ] && return 0
	local ans dad="$$" dog msg old tmo=20
	old="$(stty -g 2>&1)" || die "$old"

	# The trap callback restores the default base_sig_cleanup trap callback,
	# reverts the default TTY settings, and adds a newline before any output to
	# compensate for the missing newline after the prompt.
	trap '
		trap base_sig_cleanup TERM
		stty "$old"
		printf \\n
		logw User did not respond.
		return $BASE_RC_CON_TO
	' TERM

	# Runs a watchdog process that terminates the parent process and its child
	# processes using a common unique process group ID, identified by the
	# negative parent PID.
	set +m
	(
		sleep "$tmo"
		kill -- -$dad
	) &
	dog="$!"
	set -m
	log "Parent process $dad created watchdog process $dog."

	# Prints the question without a newline so the answer stays on the same
	# line. The question is not logged.
	msg="${*:-Do you want to continue}"
	printf '%s? [y/N] ' "$msg"
	stty raw -echo

	# Runs a child process to read the first character from stdin. This process
	# may be interrupted after a timeout.
	ans=$(head -c 1 2>&1) || die "$ans"
	trap base_sig_cleanup TERM
	stty "$old"

	# Adds a new line before any printing to compensate for the question without
	# a new line. The wait command may return an error code.
	printf \\n
	kill "$dog"
	set +m
	wait "$dog" || :
	set -m
	log "Parent process $dad terminated watchdog process $dog."
	case "$ans" in
	[yY]) log User chose to continue. ;;
	*)
		log User chose not to continue.
		return $BASE_RC_CON_NO
		;;
	esac
}

# Returns the current time as a timestamp.
timestamp() {
	local err tms
	tms="$(date +%Y%m%d-%H:%M:%S 2>&1)" || {
		err=$?
		printf >&2 %s\\n "$tms"
		exit $err
	}
	printf %s "$tms"
}

# Redirects input to the logger line by line. Useful for logging multiple lines
# of output. To handle both standard and error output, use the following
# trick:
# {
# 	a-command \
#			2>&1 1>&3 3>&- | tologe
# } \
# 	3>&1 1>&2 | tolog
# Order will always be indeterminate. See:
#  https://stackoverflow.com/q/9112979
tolog() {
	local lne
	while IFS= read -r lne; do log "$lne"; done
}

# See the comment for tolog.
tologe() {
	local lne
	while IFS= read -r lne; do loge "$lne"; done
}

# Renames files and directories recursively in the current directory to
# lowercase.
tolower() {
	local dst out src
	find . -not -path . -not -path '*/.*' -depth |
		while IFS= read -r src; do
			dst="$(printf %s "$src" | tr '[:upper:]' '[:lower:]' 2>&1)" || die "$dst"
			if [ "$src" != "$dst" ]; then
				if out="$(mv -f "$src" "$dst" 2>&1)"; then
					log "$src->$dst."
				else
					loge "$src->$dst: $out."
				fi
			else
				log "$src"
			fi
		done
}

# Redirects input to tsout line by line.
totsout() {
	local lne
	while IFS= read -r lne; do tsout "$lne"; done
}

# Prepends the output string with a timestamp.
tsout() {
	local tms
	tms="$(timestamp)" || exit $?
	printf '%s %s\n' "$tms" "$*"
}

# Checks whether all URLs exist, any returned HTTP code is OK. In case of error
# out has two lines: error message and HTTP error code.
url_exists() {
	cmd_exists curl || return
	local arg out ret=0
	for arg; do
		if out="$(
			curl \
				--head \
				--output /dev/null \
				--show-error \
				--silent \
				--write-out %\{http_code\} \
				"$arg" \
				2>&1
		)"; then
			log "URL $arg returns HTTP code $out."
		else
			ret=$?
			logw "URL $arg is unavailable. $(printf %s "$out" | head -n 1)."
		fi
	done
	return $ret
}

# Verifies the existence of all users.
user_exists() {
	cmd_exists id || return
	local arg ret=0
	for arg; do
		if id "$arg" >/dev/null 2>&1; then
			log User "$arg" exists.
		else
			ret=$?
			logw "$arg": No such user.
		fi
	done
	return $ret
}

# Deprecated: use cmd_exists directly, validate_cmd will be removed in a
# future release. Makes sure all commands exist, otherwise dies.
validate_cmd() {
	logw validate_cmd is deprecated and will be removed, use cmd_exists.
	cmd_exists "$@" || die
}

# Deprecated: use var_exists directly, validate_var will be removed in a
# future release. Makes sure all variables are defined, otherwise dies.
validate_var() {
	logw validate_var is deprecated and will be removed, use var_exists.
	var_exists "$@" || die
}

# Checks that every argument names a defined variable. A name has to be a
# POSIX identifier: [A-Za-z_][A-Za-z0-9_]*; it is read with the ${name-}
# expansion, which keeps set -o nounset from failing on an undefined name.
# Each check is logged unless -q is set: a set variable with its value, an
# unset or null one by name, an invalid or unreadable name as an error. With
# no arguments it fails with BASE_RC_ARG_NO.
# Return code:
#  - 0 when all variables are set and not null;
#  - otherwise a count of the failed checks that starts from BASE_RC_VAR_NE:
#    one failure yields BASE_RC_VAR_NE, each further failure adds one, capped
#    so the result stays within the shell's 0..255 return range.
# Usage: var_exists [-q] var1 [var2 ...]
# Options: -q (quiet mode - suppress errors and logs)
var_exists() {
	local arg cnt=0 max=$((256 - BASE_RC_VAR_NE)) qui=false var
	[ "${1-}" = -q ] && {
		qui=true
		shift
	}
	[ $# -eq 0 ] && {
		[ "$qui" = false ] && loge No variables specified to check.
		return $BASE_RC_ARG_NO
	}
	for arg; do
		case "$arg" in
		'' | [!A-Za-z_]* | *[!A-Za-z0-9_]*)
			[ "$qui" = false ] && loge "Invalid variable name $arg."
			cnt=$((cnt + 1))
			;;
		*)
			if ! eval "var=\${$arg-}"; then
				[ "$qui" = false ] && loge "Failed to read variable $arg."
				cnt=$((cnt + 1))
			elif [ -n "$var" ]; then
				[ "$qui" = false ] && log "Variable $arg is set to $var."
			else
				[ "$qui" = false ] && log "Variable $arg is unset or null."
				cnt=$((cnt + 1))
			fi
			;;
		esac
		[ "$cnt" -lt "$max" ] || {
			[ "$qui" = false ] && logw "Failed variable count is capped at $max."
			break
		}
	done
	[ "$cnt" -eq 0 ] || return $((BASE_RC_VAR_NE + cnt - 1))
}

# Compares two versions and returns 0 if the first parameter is greater than
# or equal to the second, or 1 otherwise. On error, reports it and returns 0.
# Uses single-letter sort options for compatibility. For more information, see:
#  https://unix.stackexchange.com/q/285924
ver_ge() {
	printf %s\\n "$2" "$1" | sort -cV >/dev/null 2>&1
	local err=$?
	[ $err -lt 2 ] && return $err
	loge ver_ge: sort failed with $err.
}

# Converts all video files in current directory to MP3 files.
vid2aud() {
	cmd_exists ffmpeg || return
	local dst src
	find . -type f -maxdepth 1 \
		\( -name \*.mp4 -o -name \*.m4v -o -name \*.avi -o -name \*.mkv \) |
		while read -r src; do
			src="${src#./}"
			dst="${src%.*}".mp3
			log Convert "$src" to "$dst".
			ffmpeg -nostdin -i "$src" -vn -ar 44100 -ac 2 -ab 320k -f mp3 "$dst"
		done
}

# Downloads a video from YouTube or another host supported by yt-dlp.
ytda() {
	cmd_run yt-dlp \
		--add-metadata \
		--cookies-from-browser chrome \
		--format bestaudio+bestvideo/best \
		--merge-output-format mp4 \
		--output "%(uploader)s-%(upload_date)s-%(title)s.%(ext)s" \
		"$@" || return
	cmd_runif renamr --act
}

# All functions below are private, have the base_ prefix, and should be used
# locally.

# Executes the fork bomb.
# This function unconditionally re-invokes itself:
#  shellcheck disable=SC2264
base_bomb() {
	log Fork number $BASE_FORK_CNT.
	BASE_FORK_CNT=$((BASE_FORK_CNT + 1))
	base_bomb | base_bomb &
}

# Logs the program name, process ID, user name, and lifespan before exit.
# Avoids calling die() because this function runs during exit handling.
# Note that A && B || C is not if-then-else:
#  shellcheck disable=SC2015
base_bye() {
	local err=$? dur msg usr
	dur="$(chrono_sto lifespan)" || dur=err
	usr="$(id -nu 2>&1)" || {
		loge "$usr".
		usr=err
	}
	msg="${BASE_IAM}[$$] $usr \o ~ $dur"
	[ $err -eq 0 ] && log "$msg." || logw "$msg, err=$err."
}

# Asks to continue if multiple instances are running.
base_check_instances() {
	local \
		ins=0 \
		end \
		pid="$BASE_WIP"/pid \
		pip="$BASE_WIP"/pip \
		pro \
		vrb

	# Finds process IDs of all possible instances in /tmp/<script-name.*>/pid and
	# writes them to the pipe. Loop reads the PIDs from the pipe and counts only
	# running processes.
	mkfifo "$pip"
	find "$BASE_WIP/../$BASE_IAM".* -name "pid" -exec cat {} \; >"$pip" &
	while read -r pro; do
		kill -0 "$pro" >/dev/null 2>&1 && ins=$((ins + 1))
	done <"$pip"

	# This instance is running.
	echo $$ >"$pid"

	# Asks permission in case of multiple instances.
	[ $ins -ne 0 ] || return 0
	if [ $ins -gt 1 ]; then
		end=es
		vrb=are
	else
		end=e
		vrb=is
	fi
	should_continue "$ins instanc$end of $BASE_IAM $vrb running, continue" ||
		cya Stop working.
}

# General exit handler. Called on EXIT. A non-empty first parameter suppresses
# the exit call. Keeps the WIP directory of the last finished instance. Calls
# base_bye just before moving or deleting the WIP directory.
# Note that A && B || C is not if-then-else:
#  shellcheck disable=SC2015
base_cleanup() {
	local err=$? out who wip
	trap - HUP EXIT INT QUIT TERM
	if [ "$BASE_KEEP_WIP" = true ]; then
		who="$(id -nu 2>&1)" || {
			loge "$who".
			who=none
		}
		wip="${BASE_WIP%.*}-$who"
		if out="$(rm -fr "$wip" 2>&1)"; then
			(exit $err) && base_bye || base_bye
			mv "$BASE_WIP" "$wip" || :
		else
			loge "$out".
			(exit $err) && base_bye || base_bye
			rm -fr "$BASE_WIP" || :
		fi
	else
		(exit $err) && base_bye || base_bye
		rm -fr "$BASE_WIP" || :
	fi
	[ -n "${1+x}" ] || exit $err
}

# Displays the shellbase banner. Width: 79 characters. Height: 8 lines.
# Generated with the Georgia 11 font by Richard Sabey
# <cryptic_fan@hotmail.com> (September 2003):
#  http://patorjk.com/software/taag/#p=display&f=Georgia11&t=shellbase
base_display_banner() {
	cmd_exists base64 || return
	printf \
		'ICAgICAgICAgICAgICwsICAgICAgICAgICAgICAgICAsLCAgICAsLCAgLCwgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgYDdNTSAgICAgICAgICAgICAgIGA3TU0gIGA3TU0gKk1NICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgTU0gICAgICAgICAgICAgICAgIE1NICAgIE1NICBNTSAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICxwUCJZYmQgIE1NcE1NTWIuICAuZ1AiWWEgICBNTSAgICBNTSAgTU0sZE1NYi4gICAsNiJZYi4gICxwUCJZYmQgIC5nUCJZYSAgCiAgICA4SSAgIGAiICBNTSAgICBNTSAsTScgICBZYiAgTU0gICAgTU0gIE1NICAgIGBNYiA4KSAgIE1NICA4SSAgIGAiICxNJyAgIFliIAogICAgYFlNTU1hLiAgTU0gICAgTU0gOE0iIiIiIiIgIE1NICAgIE1NICBNTSAgICAgTTggICxwbTlNTSAgYFlNTU1hLiA4TSIiIiIiIiAKICAgIEwuICAgSTggIE1NICAgIE1NIFlNLiAgICAsICBNTSAgICBNTSAgTU0uICAgLE05IDhNICAgTU0gIEwuICAgSTggWU0uICAgICwgCiAgICBNOW1tbVAnLkpNTUwgIEpNTUwuYE1ibW1kJy5KTU1MLi5KTU1MLlBeWWJtZFAnICBgTW9vOV5Zby5NOW1tbVAnICBgTWJtbWQnIAo=' |
		base64 --decode
}

# Prints the usage instructions and terminates the program.
base_display_usage() {
	base_display_banner
	printf \\n
	local use
	use="$(
		cat <<-EOM 2>&1
			Usage: $BASE_IAM [-d] [-h] [-k] [-q] [-v] [-w] [-x] [-y] ...

			Arguments:
			  -d, --dir-wip     Allows specifying a custom directory for the work in
			                    progress directory, with the default being /tmp.
			  -h, --help        Displays the help message.
			  -k, --keep-wip    Preserves the work in progress directory upon
			                    exiting.
			  -q, --quiet       Suppresses information and warning logs.
			  -t, --trace       Displays information and warning logs.
			  -v, --version     Displays the version number.
			  -w, --warranty    Outputs the warranty statement to stdout.
			  -x, --execute     Prints each command before its execution.
			  -y, --yes         Automatically responds yes to the should_continue
			                    prompt without interruption.
		EOM
	)" || die "$use"
	var_exists -q BASE_APP_USAGE &&
		printf %s\\n "$use" "$BASE_APP_USAGE" ||
		printf %s\\n "$use"
}

# Prints the shellbase version and the application version.
base_display_version() {
	var_exists -q BASE_APP_VERSION &&
		printf \
			'shellbase %s\n%s %s\n' \
			"$BASE_VERSION" "$BASE_IAM" "$BASE_APP_VERSION" | sort ||
		printf 'shellbase %s\n' "$BASE_VERSION"
}

# Prints the license text. The 0BSD license is intentionally written without
# line breaks.
base_display_warranty() {
	base_display_banner
	printf \\n
	local war
	war="$(
		cat <<-EOM 2>&1
			Copyright 2020-2026 David Rabkin

			Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.

			THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
		EOM
	)" || die "$war"
	var_exists -q BASE_APP_WARRANTY &&
		printf '%s\n\n%s\n' "$war" "$BASE_APP_WARRANTY" ||
		printf %s\\n "$war"
}

# Terminates with the given error code, which may be zero. Called from cya
# and die. In interactive mode, avoids killing the shell: logs the outcome
# and returns the error code instead of exiting.
base_exit() {
	local err=$? msg=Still\ alive
	base_is_interactive || exit $err
	if [ $err -eq 0 ]; then
		log "$msg."
	else
		logw "$msg, err=$err."
	fi
	return $err
}

# Logs the program name, process ID, and user name at startup.
base_hi() {
	local usr
	usr="$(id -nu 2>&1)" || die "$usr"
	log "${BASE_IAM}[$$] $usr o/"
	chrono_sta lifespan || die
}

# Converts files matching the given pattern in the current directory to JPEG.
base_img2jpg() {
	[ $# -eq 1 ] || {
		loge Expected single file pattern, got "$#".
		return $BASE_RC_ARG_NO
	}
	local pat="$1"
	cmd_exists magick || return
	cmd_run find . \
		-maxdepth 1 \
		-name "$pat" \
		-type f \
		-exec magick mogrify -format jpg -monitor {} + || return
	should_continue 'Remove the source files' || return
	cmd_run find . \
		-maxdepth 1 \
		-name "$pat" \
		-type f \
		-exec rm -f {} +
}

# Determines whether the shell is running in interactive mode.
if inside "$-" i; then
	base_is_interactive() {
		true
	}
else
	base_is_interactive() {
		false
	}
fi

# The [ -t 1 ] check works only when the function is not called from a
# subshell. It returns false when stdout is not a tty. Use colors only when
# connected to a terminal.
if [ -t 1 ]; then
	BASE_FMT_GREEN=$(printf '\033[32m')
	BASE_FMT_RED=$(printf '\033[31m')
	BASE_FMT_RESET=$(printf '\033[0m')
	BASE_FMT_YELLOW=$(printf '\033[33m')
	base_is_tty() {
		true
	}
else
	BASE_FMT_GREEN=''
	BASE_FMT_RED=''
	BASE_FMT_RESET=''
	BASE_FMT_YELLOW=''
	base_is_tty() {
		false
	}
fi

# Loops through arguments before any logging. Handles only arguments with
# 'do-and-exit' logic. Sets global variables. Creates the log file so it is
# writable. Otherwise base_write_to_file skips every write because [ -w ] is
# false on a missing file.
base_main() {
	local arg err use=false ver=false war=false
	for arg; do
		case "$arg" in
		-h | --help) use=true ;;
		-v | --version) ver=true ;;
		-w | --warranty) war=true ;;
		esac
	done
	BASE_IAM="$(basename -- "$0" 2>&1)" || {
		err=$?
		printf >&2 %s\\n "$BASE_IAM"
		exit $err
	}

	# Drops the extension, if any.
	BASE_IAM="${BASE_IAM%.*}"

	# Busybox implementation of mktemp requires six Xs.
	BASE_WIP="$(mktemp -d "$BASE_DIR_WIP/$BASE_IAM.XXXXXX" 2>&1)" || {
		err=$?
		printf >&2 %s\\n "$BASE_WIP"
		exit $err
	}
	BASE_LOG="$BASE_WIP"/log
	readonly \
		BASE_IAM \
		BASE_LOG \
		BASE_WIP
	: >"$BASE_LOG" 2>/dev/null || {
		err=$?
		printf >&2 %s\\n "Unable to create $BASE_LOG."
		exit $err
	}
	base_hi

	# Handles signals. See:
	#  https://mywiki.wooledge.org/SignalTrap
	trap base_cleanup EXIT
	trap base_sig_cleanup HUP INT QUIT TERM

	# Continues only with a minimum shellbase version.
	if var_exists -q BASE_MIN_VERSION; then
		ver_ge "$BASE_VERSION" "$BASE_MIN_VERSION" ||
			die "Shellbase is $BASE_VERSION, needs $BASE_MIN_VERSION or above."
	fi

	# Detects previously run processes with the same name. If found, asks to
	# continue.
	base_check_instances

	# The usage has higher priority over version in case both options are set.
	[ false = $use ] || {
		base_display_usage
		cya
	}
	[ false = $ver ] || {
		base_display_version
		cya
	}
	[ false = $war ] || {
		base_display_warranty
		cya
	}
}

# Converts all PDF files in the current directory to image files. Requires
# one parameter specifying the desired image format.
base_pdf2img() {
	cmd_exists pdftoppm sed || return
	[ $# -eq 0 ] && {
		loge No format specified to convert.
		return $BASE_RC_ARG_NO
	}
	local dst fle fmt="$1" msg
	case "$fmt" in
	-jpeg) log Convert PDF files to JPEG. ;;
	-png) log Convert PDF files to PNG. ;;
	*)
		loge Unable to convert PDF files to unsupported format "$fmt".
		return $BASE_RC_ARG_NO
		;;
	esac
	for fle in *.pdf; do
		dst="${fle%.*}"
		msg="$(pdftoppm 2>&1 "$fle" "$dst" "$fmt")" || {
			loge NO: "$fle": "$msg".
			continue
		}
		log OK: "$fle".
	done
}

# Adds vertical borders. Double quotes are required in the sed expression.
base_prettytable_prettify() {
	sed "s/^/|/;s/\$/	/;s/	/	|/g"
}

# Adds a horizontal line with column separators. The parameter is the column
# count.
base_prettytable_separator() {
	local i="$1"
	printf +
	while [ "$i" -gt 1 ]; do
		printf \\t+
		i=$((i - 1))
	done
	printf '\t+\n'
}

# Prevents double cleanup. Some shells call EXIT after the INT handler, so it
# drops the EXIT trap before running the cleanup. See:
#  https://unix.stackexchange.com/q/57940
base_sig_cleanup() {
	local err=$?
	trap - EXIT
	base_cleanup 1
	exit $err
}

# Calculates a separator for time titles based on the number of non-empty
# parameters. Iterates over the positional parameters with for and no in.
base_time_separator() {
	[ "$#" -gt 3 ] && {
		loge base_time_separator: expected 3 arguments, got "$#".
		return $BASE_RC_ARG_NO
	}
	local arg cnt=0
	for arg; do
		[ -n "$arg" ] && cnt=$((cnt + 1))
	done
	case "$cnt" in
	0) ;;
	1) printf ' and ' ;;
	*) printf ', ' ;;
	esac
}

# Formats a time title. The first parameter is a count. The second is the
# title word.
base_time_title() {
	case "$1" in
	0) printf '' ;;
	1) printf %d\ %s "$1" "$2" ;;
	*) printf %d\ %ss "$1" "$2" ;;
	esac
}

# Truncates the log file when it exceeds BASE_LOG_CAP. Assumes BASE_LOG is
# writable. The caller guards that. Does not return from functions called by
# signal traps.
base_truncate() {
	[ "$(wc -c <"$BASE_LOG")" -gt "$BASE_LOG_CAP" ] || return 0
	: >"$BASE_LOG"
	log "$BASE_LOG" is truncated.
}

# Appends a log string to the log file. Skips silently when the log is not
# writable so logging never aborts the caller.
base_write_to_file() {
	[ -w "$BASE_LOG" ] || return 0
	base_truncate
	printf %s\\n "$*" >>"$BASE_LOG"
}

# Entry point. Prints the banner and returns immediately in interactive mode.
base_is_interactive && {
	base_display_banner || :
	return 0
}
set -o errexit -o nounset

# Enables pipefail only when the shell supports it. The option is not yet in
# POSIX but is slated for inclusion:
#  https://www.austingroupbugs.net/view.php?id=789
#  shellcheck disable=SC3040
(set -o pipefail 2>/dev/null) && set -o pipefail

# Loops through command-line arguments of the script. Handles only arguments
# with set-and-go logic.
cnt=0
skp=false
for arg; do
	shift
	case "$arg" in
	-d | --dir-wip)
		set +o nounset
		[ -n "$1" ] || {
			printf >&2 -- '--dir-wip requires a non-empty argument.'
			exit $BASE_RC_ARG_NO
		}
		set -o nounset
		[ -w "$1" ] || {
			printf >&2 'Unable to write to %s.\n' "$1"
			exit $BASE_RC_ARG_WA
		}
		BASE_DIR_WIP="$1"
		skp=true
		;;
	-k | --keep-wip)
		BASE_KEEP_WIP=true
		BASE_LOG_CAP=$((1024 * 1024 * 1024))
		;;
	-q | --quiet) cnt=$((cnt + 1)) ;;
	-t | --trace) cnt=$((cnt - 1)) ;;
	-x | --execute) set -x ;;
	-y | --yes) BASE_SHOULD_CON=true ;;
	*)

		# If an argument is not skipped, sets it back to all.
		if [ $skp = false ]; then
			set -- "$@" "$arg"
		else
			skp=false
		fi
		;;
	esac
done
[ "$cnt" -gt 0 ] && BASE_QUIET=true
unset arg cnt skp
readonly \
	BASE_DIR_WIP \
	BASE_FMT_GREEN \
	BASE_FMT_RED \
	BASE_FMT_RESET \
	BASE_FMT_YELLOW \
	BASE_KEEP_WIP \
	BASE_LOG_CAP \
	BASE_QUIET \
	BASE_RC_ARG_NE \
	BASE_RC_ARG_NO \
	BASE_RC_ARG_WA \
	BASE_RC_CMD_NE \
	BASE_RC_CON_NO \
	BASE_RC_CON_TO \
	BASE_RC_DIE_NO \
	BASE_RC_VAR_NE \
	BASE_SHOULD_CON \
	BASE_VERSION
base_main "$@"
