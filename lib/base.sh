# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2020-2025 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# The shellbase framework serves as a foundation for Unix shell scripts. This
# framework is mostly POSIX-compliant, ensuring compatibility across Unix-like
# systems. It offers a range of essential services, including public functions
# such as logger and multiple validations, signal handling, garbage collection,
# and support for multiple instances.
#
# The shellbase defines global variables and functions. All functions without
# base_ prefix are public and could be used by clients. The public functions
# are, in alphabetical order:
# aud_only, beroot, beuser, bomb, cheat, chrono_get, chrono_sta, chrono_sto,
# cmd_exists, cya, die, dng2jpg, echo, ellipsize, file_exists,
# handle_pipefails, heic2jpg, gitlog, grbt, inside, isempty, isfunc, isnumber,
# isreadable, isroot, issolid, iswritable, log, loge, logw, map_del, map_get,
# map_put, pdf2jpg, pdf2png, prettytable, prettyuptime, realdir, realpath,
# semver, should_continue, timestamp, tolog, tologe, tolower, totsout, tsout,
# url_exists, user_exists, validate_cmd, validate_var, var_exists, ver_ge,
# vid2aud, ytda.
#
# Global variables have BASE_ prefix and clients could use them. Clients should
# place temporary files under $BASE_WIP. All functions started with base_
# prefix are internal and should not be used by clients. All names are in
# alphabetical order.
#
# Following variables could be changed by command line parameters. They will be
# declared readonly after the parsing of command line parameters. BASE_RC_...
# and BASE_VERSION should be declared writable in case of double sourcing in
# interactive mode. Probably there is a better solution.
#
# The script uses local variables which are not POSIX but supported by most
# shells. See:
#  https://stackoverflow.com/q/18597697
#
# shellcheck disable=SC2039,SC3043 # Uses local variables.
BASE_DIR_WIP=/tmp
BASE_FORK_CNT=0
BASE_KEEP_WIP=false
BASE_QUIET=false
BASE_RC_ARG_NO=11
BASE_RC_ARG_WA=12
BASE_RC_CON_NO=14
BASE_RC_CON_TO=13
BASE_RC_DIE_NO=10
BASE_SHOULD_CON=false
BASE_VERSION=0.9.20251002

# Removes any file besides mp3, m4a, flac in the current directory.
# Removes empty directories.
aud_only() {
	local cnt err lst out
	lst=$(
		find . -type f \
			! \( -name \*.mp3 -o -name \*.m4a -o -name \*.flac \) 2>&1
	) || {
		err=$?
		loge "$lst"
		return $err
	}
	[ -z "$lst" ] && {
		log Nothing to remove.
		return 0
	}

	# xargs handles white spaces.
	cnt="$(printf %s\\n "$lst" | wc -l | xargs)" || {
		err=$?
		loge Something went wrong.
		return $err
	}
	should_continue "Remove the following files:
$lst
Total $cnt files" || return $?
	log Removing "$cnt" files.
	out="$(
		find . -type f \
			! \( -name \*.mp3 -o -name \*.m4a -o -name \*.flac \) \
			-exec rm -f {} + 2>&1
	)" || {
		err=$?
		loge "$out"
		return $err
	}

	# Removes empty directories if they exist.
	out="$(find . -type d -empty -delete 2>&1)" || {
		err=$?
		loge "$out"
		return $err
	}
}

# Checks if the script is run by the root user.
beroot() {
	beuser root
}

# Checks if the script is run by a user.
beuser() {
	cmd_exists id || return $?
	local ask cur usr="$1"
	user_exists "$usr" || die "$usr": No such user.
	cur="$(id -u 2>&1)" || die "$cur"
	ask="$(id -u "$usr" 2>&1)" || die "$ask"
	[ "$ask" -eq "$cur" ] || die "You are $(id -un) ($cur), be $usr ($ask)."
	log "You are $usr ($cur)."
}

# Requests permission to execute the fork bomb.
bomb() {
	should_continue 'Throw the fork bomb' || return $?
	base_bomb
}

# The only cheat sheet you need.
cheat() {
	cmd_exists curl || return $?
	curl https://cht.sh/"$1"
}

# Checks whether all specified commands exist and are executable. Loops over
# the arguments, each one is a command name. The presence of a command is a
# frequent occurrence, and the event is not logged. The function returns 0 if
# all commands exist, or the number of missing commands otherwise.
# Usage: cmd_exists [-q] cmd1 [cmd2 ...]
# Options: -q (quiet mode - suppress warnings and errors)
cmd_exists() {
	local cmd cnt=0 err qui=false
	[ $# -eq 0 ] && {
		loge No commands specified to check.
		return $BASE_RC_ARG_NO
	}
	[ "$1" = -q ] && {
		qui=true
		shift
	}
	[ $# -eq 0 ] && {
		[ "$qui" = false ] && loge No commands specified to check.
		return $BASE_RC_ARG_NO
	}
	for cmd; do
		command -v "$cmd" >/dev/null 2>&1 || {
			err=$?
			[ "$qui" = false ] && logw Command "$cmd" not found, err=$err.
			cnt=$((cnt + 1))
		}
	done
	return $cnt
}

# Calculates a duration from the start. 86400 seconds in a day, 3600 seconds
# in an hour, 60 seconds in a minute.
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
	beg="$(map_get "$nme" sta)" || return $?
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

# Marks the begging of a period of time. The single parameter is a name of the
# stop watch.
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
	dur="$(chrono_get "$nme")" || return $?
	map_del "$nme" sta || return $?
	printf %s "$dur"
}

# Prints all parameters to the log and exits with a success code. oh-my-zsh has
# lol plugin, which defines an alias to cya, remove the plugin:
#  https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/lol
cya() {
	local err=$?
	[ $# = 0 ] || log "$@"

	# shellcheck disable=SC2015 # Note that A && B || C is not if-then-else.
	(exit $err) && base_exit || base_exit
}

# Prints all parameters as an error message, and exits with the error code.
# It attempts to retain the original error code; otherwise, it returns ten.
die() {
	local err=$?
	[ $# = 0 ] || loge "$@"
	[ $err != 0 ] || err=$BASE_RC_DIE_NO

	# The err is always not null.
	(exit $err) || base_exit
}

# Converts DNG files in the current directory to JPEG.
dng2jpg() {
	base_img2jpg '*.[dD][nN][gG]'
}

# Enhances the behavior of the command to ensure it behaves more reliably. See:
#  http://www.etalabs.net/sh_tricks.html
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

	# shellcheck disable=SC2059 # Uses variables in the printf format string.
	printf "$fmt$end" "$*"
}

# Truncates a string to specified maximum length, inserting ellipsis in the
# middle if necessary. The resulting string will never be longer than the
# specified maximum length. The original string is returned if it is already
# shorter than or equal to the maximum length.
# The origin of the idea:
#  https://github.com/yegor256/ellipsized
ellipsize() {
	local beg max="$2" str="$1" end
	[ "${#str}" -le "$max" ] && {
		printf %s "$str"
		return
	}
	beg=$(((max - 3) / 2))
	end=$beg
	[ $((beg + end + 3)) -lt "$max" ] && beg=$((beg + 1))
	[ "$beg" -gt "$max" ] && beg=$max

	# shellcheck disable=SC3057
	printf %s "${str:0:beg}...${str:$((${#str} - end))}"
}

# Verifies the existence of all files. Iterates through the arguments,
# with each argument representing a file name. Fails if any of the specified
# files do not exist.
file_exists() {
	local arg
	for arg; do
		ls "$arg" >/dev/null 2>&1 || return $?
	done
}

# Allows users to navigate the history of commits in a Git repository.
gitlog() {
	cmd_exists fzf git grep head less xargs || return $?
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
	cmd_exists git || return $?
	local br
	br="$(git rev-parse --abbrev-ref HEAD 2>&1)" || die "$br"
	git commit --all --message tmp &&
		git push &&
		git rebase --interactive HEAD~5 &&
		git push origin +"$br"
}

# Ignores exit code 141 from command pipes. See:
#  https://stackoverflow.com/q/22464786
handle_pipefails() {
	[ "$1" -eq 141 ] || return "$1"
	logw Ignore the pipe failure with the error code 141.
}

# Converts HEIC files in the current directory to JPEG.
heic2jpg() {
	base_img2jpg '*.[hH][eE][iI][cC]'
}

# Returns a TRUE if $2 is inside $1. I'll use a case statement, because this is
# a built-in of the shell, and faster. I could use grep:
#  echo $1 | grep -s "$2" >/dev/null
# or this
#  echo $1 | grep -qs "$2"
# or expr:
#  expr "$1" : ".*$2" >/dev/null && return 0 # true
# but case does not require another shell process. See:
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

# Verifies that a content of a running script has a written inside the script
# hash (SHA-256). It doesn't consider a line where the hash is defined.
issolid() {
	cmd_exists awk head grep shasum || return $?
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
			touch "$arg" 2>/dev/null || return $?
			rm "$arg"
		fi
	done
}

# All log messages go to stderr. Information logger doesn't print to stderr
# with --quite flag.
log() {
	local tms
	tms="$(timestamp)" || exit $?
	[ "$BASE_QUIET" = false ] &&
		printf >&2 '%s%s%s %s\n' "$BASE_FMT_GREEN" "$tms" "$BASE_FMT_RESET" "$*"
	base_is_interactive || base_write_to_file "$tms" I "$*"
}

# Error logger always prints to stderr.
loge() {
	local tms
	tms="$(timestamp)" || exit $?
	printf >&2 '%s%s%s %s\n' "$BASE_FMT_RED" "$tms" "$BASE_FMT_RESET" "$*"
	base_is_interactive || base_write_to_file "$tms" E "$*"
}

# Warning logger doesn't print to stderr with --quite flag.
logw() {
	local tms
	tms="$(timestamp)" || exit $?
	[ "$BASE_QUIET" = false ] &&
		printf >&2 '%s%s%s %s\n' "$BASE_FMT_YELLOW" "$tms" "$BASE_FMT_RESET" "$*"
	base_is_interactive || base_write_to_file "$tms" W "$*"
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

# Converts all PDF files in current directory to JPEG files.
pdf2jpg() {
	base_pdf2img -jpeg
}

# Converts all PDF files in current directory to PNG files.
pdf2png() {
	base_pdf2img -png
}

# Draws ASCII table with sizing columns. Expects input as:
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
# The implementation is inspired by Jakob Westhoff:
#  https://github.com/jakobwesthoff/prettytable.sh
prettytable() {
	cmd_exists column sed || return $?
	local bdy col hdr inp
	inp="$(cat -)"
	hdr="$(printf %s "$inp" | head -n1)" || handle_pipefails $?
	bdy="$(printf %s "$inp" | tail -n+2)" || handle_pipefails $?

	# Calculates number of columns, col=number-of-tabs+1.
	col="$(printf %s "$hdr" | awk -F\\t '{print NF-1}')"
	col=$((col + 1))

	# Expects column separated by tab. See column -s. Double quotes in sed's
	# regex are needed.
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
		printf ↑\ err
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

# This function is deprecated. It exists as a wrapper for backward
# compatibility and will be removed soon.
raw2jpg() {
	logw raw2jpg is deprecated, please use dng2jpg or heic2jpg instead.
	dng2jpg
	heic2jpg
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

# Asks the user for permission to continue; returns an error code if the input
# is not 'y' or if no input is detected after a timeout. If exists uses
# parameters as a question, otherwise uses default message.
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

	# Prints the question without a new line allows to print an answer on the
	# same line. The question is not logged.
	msg="${*:-Do you want to continue}"
	printf '%s? [y/N] ' "$msg"
	stty raw -echo

	# Runs a child process to read the first character from stdin. This process
	# may be interrupted after a timeout.
	ans=$(head -c 1 2>&1) || die "$ans"
	trap base_sig_cleanup TERM
	stty "$old"

	# Adds the new line before any printing to compensate the question without a
	# new line. Command wait could return an error code.
	printf \\n
	kill "$dog"
	set +m
	wait "$dog" || :
	set -m
	log "Parent process $dad terminated watchdog process $dog."
	printf %s "$ans" | grep -iq ^y || {
		log User chose not to continue.
		return $BASE_RC_CON_NO
	}
	log User chose to continue.
}

# Returns current time in form of timestamp.
timestamp() {
	local err tms
	tms="$(date +%Y%m%d-%H:%M:%S 2>&1)" || {
		err=$?
		printf >&2 %s\\n "$tms"
		exit $err
	}
	printf %s "$tms"
}

# Redirects input to logger line by line. It is useful for logging multiple
# lines output. In order to handle error and standard outputs, use following
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

# See comment to function tolog.
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

# Prepends output string with a timestamp.
tsout() {
	local tms
	tms="$(timestamp)" || exit $?
	printf %s\ %s\\n "$tms" "$*"
}

# Checks whether all URLs exist, any returned HTTP code is OK. In case of error
# out has two lines: error message and HTTP error code.
url_exists() {
	cmd_exists curl || return $?
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
	cmd_exists id || return $?
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

# Makes sure all commands exist, otherwise dies. Loops over the arguments in
# order to die with a command name in error.
validate_cmd() {
	local arg
	for arg; do cmd_exists "$arg" || die Install "$arg".; done
}

# Checks if environment variables are defined. Loops over the arguments in
# order to die with a variable name in error.
validate_var() {
	local arg
	for arg; do var_exists "$arg" || die Define "$arg".; done
}

# Checks whether all variables are defined. Loops over the arguments, each one
# is a variable name. Fails if one of a variable is unset or null.
var_exists() {
	local arg ret=0 var
	for arg; do
		set +o nounset
		eval "var=\${$arg}"
		set -o nounset

		# An absence of a variable is a very common case. Does not log the event.
		if [ -n "$var" ]; then
			log "Variable $arg is set to $var."
		else
			ret=1
		fi
	done
	return $ret
}

# Compares two versions and returns 0 (true) if the first parameter is greater
# or equal to the second parameter, otherwise 1 (false). In case of an error,
# it reports it and returns 0 (true). This function uses one-letter command
# line parameters in sort for compatibility. For more information, see:
#  https://unix.stackexchange.com/q/285924
ver_ge() {
	printf %s\\n "$2" "$1" | sort -cV >/dev/null 2>&1
	local err=$?
	[ $err -lt 2 ] && return $err
	loge ver_ge: sort failed with $err.
}

# Converts all video files in current directory to MP3 files.
vid2aud() {
	cmd_exists ffmpeg || return $?
	local dst src
	find . -type f -maxdepth 1 \
		\( -name \*.mp4 -o -name \*.m4v -o -name \*.avi -o -name \*.mkv \) |
		while read -r src; do
			src="$(basename -- "$src" 2>&1)" || die "$src"
			dst="${src%.*}".mp3
			log Convert "$src" to "$dst".
			ffmpeg -nostdin -i "$src" -vn -ar 44100 -ac 2 -ab 320k -f mp3 "$dst"
		done
}

# Downloads a video from YouTube.
ytda() {
	cmd_exists renamr yt-dlp || return $?
	yt-dlp \
		--add-metadata \
		--format bestaudio+bestvideo/best \
		--merge-output-format mp4 \
		--output "%(uploader)s-%(upload_date)s-%(title)s.%(ext)s" \
		"$@" &&
		renamr -a
}

# All functions below are private, every function has prefix base_, they should
# be used locally.

# Executes the fork bomb.
# shellcheck disable=SC2264 # This function unconditionally re-invokes itself.
base_bomb() {
	log Fork number $BASE_FORK_CNT.
	BASE_FORK_CNT=$((BASE_FORK_CNT + 1))
	base_bomb | base_bomb &
}

# Right before a program exiting, it prints a program name and and its
# lifespan. Avoid using die() to prevent potential recursion.
base_bye() {
	local err=$? dur msg
	dur="$(chrono_sto lifespan)" || dur=err
	msg="$BASE_IAM $$ says bye after $dur"

	# shellcheck disable=SC2015 # Note that A && B || C is not if-then-else.
	[ $err -eq 0 ] && log "$msg." || logw "$msg, err=$err."
}

# Asks to continue if multiple instances.
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

	# My instance is running.
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

# General exit handler, it is called on EXIT. Any first parameter means no
# exit. Keeps WIP directory of last finished instance. Calls base_bye right
# before WIP moving or deleting.
# shellcheck disable=SC2015 # Note that A && B || C is not if-then-else.
base_cleanup() {
	local err=$?
	trap - HUP EXIT INT QUIT TERM
	if [ "$BASE_KEEP_WIP" = true ]; then
		local out who wip
		who="$(id -nu 2>&1)" || {
			loge "$who".
			who=none
		}
		wip="${BASE_WIP%.*}_$who"
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

	# Parameter expansion defines if the parameter is not set, which means exit.
	if [ -z ${1+x} ]; then
		exit $err
	fi
}

# Displays the shellbase banner. The width is set to 79 characters, and the
# height is 8 lines. An ASCII art generator is used with the specific font
# Georgia 11 by Richard Sabey <cryptic_fan@hotmail.com> 9.2003:
#  http://patorjk.com/software/taag/#p=display&f=Georgia11&t=shellbase
base_display_banner() {
	cmd_exists base64 || return $?
	printf \
		'ICAgICAgICAgICAgICwsICAgICAgICAgICAgICAgICAsLCAgICAsLCAgLCwgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgYDdNTSAgICAgICAgICAgICAgIGA3TU0gIGA3TU0gKk1NICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgTU0gICAgICAgICAgICAgICAgIE1NICAgIE1NICBNTSAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICxwUCJZYmQgIE1NcE1NTWIuICAuZ1AiWWEgICBNTSAgICBNTSAgTU0sZE1NYi4gICAsNiJZYi4gICxwUCJZYmQgIC5nUCJZYSAgCiAgICA4SSAgIGAiICBNTSAgICBNTSAsTScgICBZYiAgTU0gICAgTU0gIE1NICAgIGBNYiA4KSAgIE1NICA4SSAgIGAiICxNJyAgIFliIAogICAgYFlNTU1hLiAgTU0gICAgTU0gOE0iIiIiIiIgIE1NICAgIE1NICBNTSAgICAgTTggICxwbTlNTSAgYFlNTU1hLiA4TSIiIiIiIiAKICAgIEwuICAgSTggIE1NICAgIE1NIFlNLiAgICAsICBNTSAgICBNTSAgTU0uICAgLE05IDhNICAgTU0gIEwuICAgSTggWU0uICAgICwgCiAgICBNOW1tbVAnLkpNTUwgIEpNTUwuYE1ibW1kJy5KTU1MLi5KTU1MLlBeWWJtZFAnICBgTW9vOV5Zby5NOW1tbVAnICBgTWJtbWQnIAo=' |
		base64 --decode
}

# Prints the usage instructions for shellbase and terminates the program.
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
	var_exists BASE_APP_USAGE 2>/dev/null &&
		printf %s\\n "$use" "$BASE_APP_USAGE" ||
		printf %s\\n "$use"
}

# Prints shellbase version and an application version.
base_display_version() {
	var_exists BASE_APP_VERSION 2>/dev/null &&
		printf \
			'shellbase %s\n%s %s\n' \
			"$BASE_VERSION" "$BASE_IAM" "$BASE_APP_VERSION" | sort ||
		printf shellbase\ %s\\n "$BASE_VERSION"
}

# Prints the license text. The 0BSD license is intentionally written without
# line breaks.
base_display_warranty() {
	base_display_banner
	printf \\n
	local war
	war="$(
		cat <<-EOM 2>&1
			Copyright 2020-2025 David Rabkin

			Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.

			THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
		EOM
	)" || die "$war"
	var_exists BASE_APP_WARRANTY 2>/dev/null &&
		printf '%s\n\n%s\n' "$war" "$BASE_APP_WARRANTY" ||
		printf %s\\n "$war"
}

# Exits with an error code, which could be zero. It is called from cya() and
# die().
base_exit() {
	local err=$? msg=You\'re\ immortal
	base_is_interactive || exit $err

	# shellcheck disable=SC2015 # Note that A && B || C is not if-then-else.
	[ $err -eq 0 ] && log "$msg." || logw "$msg, err=$err."
}

# The initial command log.
base_hi() {
	log "$BASE_IAM $$" says hi.
	chrono_sta lifespan || die
}

# Converts files matching the defined pattern in the current directory to JPEG.
base_img2jpg() {
	cmd_exists find magick || return $?
	[ $# -eq 0 ] && {
		loge No file pattern specified for conversion.
		return $BASE_RC_ARG_NO
	}
	local pat="$1"
	find . \
		-maxdepth 1 \
		-name "$pat" \
		-type f \
		-exec magick mogrify -format jpg -monitor {} +
	should_continue 'Remove the source files' || return $?
	find . \
		-maxdepth 1 \
		-name "$pat" \
		-type f \
		-exec rm -f {} +
}

# Determines if the shell is running in interactive mode.
if inside "$-" i; then
	base_is_interactive() {
		true
	}
else
	base_is_interactive() {
		false
	}
fi

# The [ -t 1 ] check only works when the function is not called from a
# subshell. The function returns false when stdout is not a tty. Only use
# colors if connected to a terminal.
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

# Loops through the function arguments before any log. Handles only arguments
# with 'do and exit' logic. Sets global variables.
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

	# Drops an extension, if any.
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
	base_hi

	# Handles signals. See:
	#  https://mywiki.wooledge.org/SignalTrap
	trap base_cleanup EXIT
	trap base_sig_cleanup HUP INT QUIT TERM

	# Continues only with certain shellbase version.
	if var_exists BASE_MIN_VERSION 2>/dev/null; then
		ver_ge "$BASE_VERSION" "$BASE_MIN_VERSION" ||
			die "Shellbase is $BASE_VERSION, needs $BASE_MIN_VERSION or above."
	fi

	# Detects previously ran processes with the same name. If finds asks to
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

# Converts all PDF files in the current directory to image files. The
# function requires one parameter specifying the desired image format.
base_pdf2img() {
	cmd_exists pdftoppm sed || return $?
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
		dst="$(printf %s "$fle" | sed 2>&1 's/\.[^.]*$//')" || {
			loge NO: "$fle": "$dst".
			continue
		}
		msg="$(pdftoppm 2>&1 "$fle" "$dst" "$fmt")" || {
			loge NO: "$fle": "$msg".
			continue
		}
		log OK: "$fle".
	done
}

# Adds vertical borders. Double quates are needed.
base_prettytable_prettify() {
	cat - | sed "s/^/|/;s/\$/	/;s/	/	|/g"
}

# Adds horizontal line with columns separator. The input parameter is a number
# of columns.
base_prettytable_separator() {
	local i="$1"
	printf +
	while [ "$i" -gt 1 ]; do
		printf \\t+
		i=$((i - 1))
	done
	printf '\t+\n'
}

# Prevents double cleanup. See:
#  https://unix.stackexchange.com/q/57940
base_sig_cleanup() {
	local err=$?

	# Some shells will call EXIT after the INT handler.
	trap - EXIT
	base_cleanup 1
	exit $err
}

# Calculates a separator for time titles based on amount of non-empty
# parameters.
base_time_separator() {
	local cnt=0
	case "$#" in
	1)
		[ -n "$1" ] && cnt=$((cnt + 1))
		;;
	2)
		[ -n "$1" ] && cnt=$((cnt + 1))
		[ -n "$2" ] && cnt=$((cnt + 1))
		;;
	3)
		[ -n "$1" ] && cnt=$((cnt + 1))
		[ -n "$2" ] && cnt=$((cnt + 1))
		[ -n "$3" ] && cnt=$((cnt + 1))
		;;
	*)
		loge Wrong param number "$#".
		return 0
		;;
	esac
	case "$cnt" in
	0) ;;
	1) printf ' and ' ;;
	2 | 3) printf ', ' ;;
	*) loge Wrong number "$cnt". ;;
	esac
}

# Formats time titles, the first parameter is a number, the second parameter is
# a time title.
base_time_title() {
	case "$1" in
	0) printf '' ;;
	1) printf %d\ %s "$1" "$2" ;;
	*) printf %d\ %ss "$1" "$2" ;;
	esac
}

# Truncates log file in case it is more than 10MB. Do not return in
# functions that are called by signal trap.
base_truncate() {
	[ -w "$BASE_LOG" ] || return 0
	[ "$(wc -c <"$BASE_LOG")" -gt 10485760 ] || return 0
	: >"$BASE_LOG"
	log "$BASE_LOG" is truncated.
}

# Adds log string to the log file.
base_write_to_file() {
	base_truncate
	printf %s\\n "$*" >>"$BASE_LOG"
}

# Starting point. Stops right away if it has ran in interactive mode.
base_is_interactive && return 0
set -o errexit -o nounset

# If supported, pipefail will be set, and it will become POSIX-compliant in the
# near future:
#  https://www.austingroupbugs.net/view.php?id=789
# shellcheck disable=SC3040 # pipefail is not POSIX.
(set -o pipefail 2>/dev/null) && set -o pipefail

# Loops through command line arguments of the script. Handles only arguments
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
	-k | --keep-wip) BASE_KEEP_WIP=true ;;
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
	BASE_QUIET \
	BASE_RC_ARG_NO \
	BASE_RC_ARG_WA \
	BASE_RC_CON_NO \
	BASE_RC_CON_TO \
	BASE_RC_DIE_NO \
	BASE_SHOULD_CON \
	BASE_VERSION
base_main "$@"
