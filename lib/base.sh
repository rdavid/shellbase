# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2020-2023 David Rabkin
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# The script uses local variables which are not POSIX but supported by most
# shells, see more:
#  https://stackoverflow.com/questions/18597697/posix-compliant-way-to-scope-variables-to-a-function-in-a-shell-script
# shellcheck disable=SC3043 # Uses local variables.
#
# shellbase is general framework for POSIX shell scripts. It provides multiple
# services: public functions (logger, validation), signals handlers, garbage
# collection, multiple instances. It asks for a permission to continue if
# multiple running instances of a same script are detected.
#
# shellbase defines global variables and functions. All functions without
# base_ prefix are public and could be used by clients. The public functions
# are, in alphabetical order:
# aud_only, be_root, be_user, cheat, cmd_exists, die, echo, file_exists,
# heic2jpg, grbt, inside, is_empty, is_func, is_readable, is_solid,
# is_writable, log, loge, logw, pdf2jpg, pdf2png, prettytable, semver,
# timestamp, to_log, to_loge, to_lower, url_exists, user_exists, validate_cmd,
# validate_var, var_exists, ver_ge, vid2aud, yes_to_continue, ytda.
#
# Global variables have BASE_ prefix and clients could use them. Clients should
# place all temporaly files under $BASE_WIP. All functions started with
# base_ prefix are internal and should not be used by clients. All names are in
# alphabetical order.
BASE_QUIET=false
BASE_VERSION=0.9.20230224

# Removes any file besides mp3, m4a, flac in current directory. Removes empty
# directories.
aud_only() {
	local ans keep
	find . -type f \
		! \( -name \*.mp3 -o -name \*.m4a -o -name \*.flac \)
	keep=$(stty -g)
	stty raw -echo
	ans=$(head -c 1)
	stty "$keep"
	printf \\n
	printf %s "$ans" | grep -iq ^y || return
	find . -type f \
		! \( -name \*.mp3 -o -name \*.m4a -o -name \*.flac \) \
		-exec rm -f {} +
	find . -type d -empty -delete
}

# Exits with error if it is not ran by root.
be_root() {
	be_user root
}

# Exits with error if it is not ran by a user.
be_user() {
	[ -z "${1-}" ] && die Usage: be_user name.
	local ask cur usr="$1"
	user_exists "$usr" || die "$usr": No such user.
	cur="$(id -u)"
	ask="$(id -u "$usr")"
	[ "$ask" -eq "$cur" ] || die "You are $(id -un) ($cur), be $usr ($ask)."
	log "You are $usr ($cur)."
}

# The only cheat sheet you need.
cheat() {
	curl https://cht.sh/"$1"
}

# Checks whether all commands exits. Loops over the arguments, each one is a
# command name.
cmd_exists() {
	[ -z "${1-}" ] || [ $# -eq 0 ] && die Usage: cmd_exists cmd1 cmd2...
	local arg ret=0
	for arg do
		if command -v "$arg" >/dev/null 2>&1; then
			log Command "$arg" exists.
		else
			ret=1
			logw Command "$arg" does not exist.
		fi
	done
	return $ret
}

# Prints all parameters as error and exits with the error code.
die() {
	[ $# -eq 0 ] || loge "$@"
	base_is_interactive && log You\'re immortal! || exit 11
}

# Repairs echo to behave in a reasonable way, see:
#  http://www.etalabs.net/sh_tricks.html
echo() (
	local end=\\n fmt=%s IFS=' '
	while [ $# -gt 1 ]; do
		case "$1" in
			[!-]*|-*[!ne]*) break;;
			*ne*|*en*) fmt=%b end=;;
			*n*) end=;;
			*e*) fmt=%b;;
		esac
		shift
	done

	# shellcheck disable=SC2059 # Uses variables in the printf format string.
	printf "$fmt$end" "$*"
)

# Checks whether all files exist. Loops over the arguments, each one is a file
# name. Fails if one of a file doesn't exist.
file_exists() {
	[ -z "${1-}" ] || [ $# -eq 0 ] && die Usage: file_exists file1 file2...
	local arg ret=0
	for arg do
		if ls "$arg" >/dev/null 2>&1; then
			log File "$arg" exists.
		else
			ret=1
			logw File "$arg" does not exist.
		fi
	done
	return $ret
}

# Creates temporary commit, rebases it and pushes.
grbt() {
	git commit --all --message tmp &&
		git push &&
		git rebase --interactive HEAD~5 &&
		git push origin +"$(git rev-parse --abbrev-ref HEAD)"
}

# Converts Apple's HEIC files in a current directory to JPEG.
heic2jpg() {
	magick mogrify -format jpg -monitor ./*.[hH][eE][iI][cC]
}

# Returns a TRUE if $2 is inside $1. I'll use a case statement, because this is
# a built-in of the shell, and faster. I could use grep:
#  echo $1 | grep -s "$2" >/dev/null
# or this
#  echo $1 | grep -qs "$2"
# or expr:
#  expr "$1" : ".*$2" >/dev/null && return 0 # true
# but case does not require another shell process.
# From here:
#  https://www.grymoire.com/Unix/Sh.html
inside() {
	[ $# -lt 2 ] && die Usage: inside body element.
	case "$1" in *$2*) return 0; esac
	return 1
}

# Decides if a directory is empty. See more:
#  https://www.etalabs.net/sh_tricks.html
is_empty() {
	[ -z "${1-}" ] || [ $# -gt 1 ] && die Usage: is_empty dir.
	cd "$1" >/dev/null 2>&1 || die Directory is not accessible: "$1".
	set -- .[!.]* ; test -f "$1" && return 1
	set -- ..?* ; test -f "$1" && return 1
	set -- * ; test -f "$1" && return 1
	return 0
}

# Determines whether a shell function with a given name exists, see:
#  https://stackoverflow.com/questions/35818555/how-to-determine-whether-a-function-exists-in-a-posix-shell
is_func() {
	case "$(type -- "$1" 2>/dev/null)" in
		*function*) return 0;;
	esac
	return 1
}

# Verifies that all parameters are readable files.
is_readable() {
	[ -z "${1-}" ] || [ $# -eq 0 ] && die Usage: is_readable file1 file2...
	local arg ret=0
	for arg do
		if [ -r "$arg" ]; then
			log File "$arg" is readable.
		else
			ret=1
			logw File "$arg" is not readable.
		fi
	done
	return $ret
}

# Verifies that a content of a running script has a written inside the script
# hash (SHA-256). It doesn't consider a line where the hash is defined.
is_solid() {
	local \
		file="$0" \
		hash \
		line \
		temp="$BASE_WIP"/hashless \
		patt=^BASE_APP_HASH
	is_readable "$file" || die File "$file" is not readable.
	line="$(
		grep --regexp "$patt" "$file"
	)" || { loge File "$file" doesn\'t have a hash.; return 1;}
	hash="$(
		printf %s "$line" | head -1 | awk -F = '{print $2}'
	)" || { loge File "$file" has hash with unknown format: "$line".; return 2;}
	grep --invert-match --regexp "$patt" "$file" > "$temp"
	printf %s\ \ %s "$hash" "$temp" | shasum --check --status ||
		{ loge Hash of "$file" does not match "$hash"; return 3;}
	log File "$file" is solid.
}

# Verifies that all parameters are writable files or do not exist.
is_writable() {
	[ -z "${1-}" ] || [ $# -eq 0 ] && die Usage: is_writable file1 file2...
	local arg ret=0
	for arg do
		if file_exists "$arg" >/dev/null 2>&1; then
			if [ -w "$arg" ]; then
				log File "$arg" is writable.
			else
				ret=1
				logw File "$arg" is not writable.
			fi
		else
			if touch "$arg" 2>/dev/null; then
				rm "$arg"
				log File "$arg" is accessible.
			else
				ret=1
				logw File "$arg" is not accessible.
			fi
		fi
	done
	return $ret
}

# Information logger doesn't print to stdout with --quite flag.
log() {
	local ts
	ts="$(timestamp)"
	[ "$BASE_QUIET" = false ] &&
		printf '\033[0;32m%s I\033[0m %s\n' "$ts" "$*"
	base_is_interactive || base_write_to_file "$ts" I "$*"
}

# Error logger always prints to stderr.
loge() {
	local ts
	ts="$(timestamp)"
	printf '\033[0;31m%s E\033[0m %s\n' "$ts" "$*" >&2
	base_is_interactive || base_write_to_file "$ts" E "$*"
}

# Warning logger doesn't print to stderr with --quite flag.
logw() {
	local ts
	ts="$(timestamp)"
	[ "$BASE_QUIET" = false ] &&
		printf '\033[0;33m%s W\033[0m %s\n' "$ts" "$*" >&2
	base_is_interactive || base_write_to_file "$ts" W "$*"
}

# Converts all PDF files in current directory to JPG files.
pdf2jpg() {
	local f
	for f in *.pdf; do
		log Convert "$f" to JPG.
		sips -s format jpeg "$f" --out "$f.jpg"
	done
}

# Converts all PDF files in current directory to PNG files.
pdf2png() {
	local f
	for f in *.pdf; do
		log Convert "$f" to PNG.
		pdftoppm "$f" "${f%.*}" -png
	done
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
	local bdy col hdr inp
	inp="$(cat -)"
	hdr="$(printf %s "$inp" | head -n1)"
	bdy="$(printf %s "$inp" | tail -n+2)"

	# Calculates number of columns, col=number-of-tabs+1.
	col="$(printf %s "$hdr" | awk -F\\t '{print NF-1}')"
	col=$((col+1))

	# Expects column separated by tab, see column -s. Double quates in sed's
	# regex are needed.
	{
		base_prettytable_separator "$col"
		printf %s\\n "$hdr" | base_prettytable_prettify
		base_prettytable_separator "$col"
		printf %s\\n "$bdy" | base_prettytable_prettify
		base_prettytable_separator "$col"
	} |
		column -ts '	' |
			sed "1s/ /-/g;3s/ /-/g;\$s/ /-/g" |
			to_log
}

# Extracts semantic versioning from a string, see https://semver.org/:
#  1.2.3
#  1.2.3+meta
#  1.2.3-4-alpha
# Uses GNU grep with PCRE option.
semver() {
	[ -z "${1-}" ] || [ $# -gt 1 ] && die Usage: semver string.
	local str="$1" ver
	ver="$(
		printf %s "$str" |
			grep --only-matching --perl-regexp \
			'(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'
	)" || {
		logw Unable to extract SemVer from "$str".
		ver=0.0.0+nil
	}
	printf %s "$ver"
}

# Returns current time in form of timestamp.
timestamp() {
	date +%Y%m%d-%H:%M:%S
}

# Redirects input to logger line by line. It is usefull for logging multiple
# lines output. In order to handle error and standard outputs, use following
# trick:
# {
# 	a-command \
#			2>&1 1>&3 3>&- | to_loge
# } \
# 	3>&1 1>&2 | to_log
# Order will always be indeterminate, see more details:
#  https://stackoverflow.com/questions/9112979/pipe-stdout-and-stderr-to-two-different-processes-in-shell-script
to_log() {
	local l
	while IFS= read -r l; do log "$l"; done
}

# See comment to function to_log.
to_loge() {
	local l
	while IFS= read -r l; do loge "$l"; done
}

# Renames files in current directory to lower case.
to_lower() {
	rename -f 'y/A-Z/a-z/' ./*
}

# Checks whether all URLs exist, any returned HTTP code is OK. In case of error
# out has two lines: error message and HTTP code 000. Uses curl, make sure it
# is installed with 'cmd_exists curl' before calling the function.
url_exists() {
	[ -z "${1-}" ] || [ $# -eq 0 ] && die Usage: url_exists url1 url2...
	local arg out ret=0
	for arg do
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
			ret=1
			logw "URL $arg is unavailable. $(printf %s "$out" | head -n 1)."
		fi
	done
	return $ret
}

# Checks whether all user exist. Uses id, make sure it is installed with
# 'cmd_exists id' before calling the function.
user_exists() {
	[ -z "${1-}" ] || [ $# -eq 0 ] && die Usage: user_exists user1 user2...
	local arg ret=0
	for arg do
		if id "$arg" >/dev/null 2>&1; then
			log User "$arg" exists.
		else
			ret=1
			logw "$arg": No such user.
		fi
	done
	return $ret
}

# Makes sure all commands exist, othewise dies. Loops over the arguments in
# order to die with a command name in error.
validate_cmd() {
	[ -z "${1-}" ] || [ $# -eq 0 ] && die Usage: validate_cmd cmd1 cmd2...
	local arg
	for arg do
		cmd_exists "$arg" || die Install "$arg".
	done
}

# Checks if environment variables are defined. Loops over the arguments in
# order to die with a variable name in error.
validate_var() {
	[ -z "${1-}" ] || [ $# -eq 0 ] && die Usage: validate_var var1 var2...
	local arg
	for arg do
		var_exists "$arg" || die Define "$arg".
	done
}

# Checks whether all variables are defined. Loops over the arguments, each one
# is a variable name. Fails if one of a variable is unset or null.
var_exists() {
	[ -z "${1-}" ] || [ $# -eq 0 ] && die Usage: var_exists var1 var2...
	local arg ret=0 var
	for arg do
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

# Compares two versions, return true if the first parameter is greater or equal
# to the second parameter. See more:
#  https://unix.stackexchange.com/questions/285924/how-to-compare-a-programs-version-in-a-shell-script
ver_ge() {
	printf %s\\n "$2" "$1" | sort --check=quiet --version-sort
}

# Converts all video files in current directory to MP3 files.
vid2aud() {
	local dst src
	find . -type f -maxdepth 1 \
		\( -name \*.mp4 -o -name \*.m4v -o -name \*.avi -o -name \*.mkv \) |
		while read -r src; do
			src="$(basename -- "$src")"
			dst="${src%.*}".mp3
			log Convert "$src" to "$dst".
			ffmpeg -nostdin -i "$src" -vn -ar 44100 -ac 2 -ab 320k -f mp3 "$dst"
		done
}

# Asks a user permission to continue, exits if not 'y'. Exits by timeout if any
# input is not detected. If exists uses parameters as a question, otherwise
# uses default message.
yes_to_continue() {
	local \
		ans \
		arc \
		dad="$$" \
		kid \
		msg \
		tmo=20
	arc="$(stty -g)"

	# The trap returns tty settings, adds the new line before any printing to
	# compensate the question without a new line.
	trap 'stty "$arc"; printf \\n; die "Timed out in $tmo seconds".' TERM

	# Runs watchdog process that kills dad and kids proceeses with common unique
	# process group ID, see minus before dad PID.
	(sleep "$tmo"; kill -- -$dad)&
	kid="$!"
	log "PIDs: dad $dad, kid $kid."

	# Prints the question without a new line allows to print an answer on the
	# same line. The question is not logged.
	msg="${*:-Do you want to continue?}"
	printf %s\ [y/N]\  "$msg"
	stty raw -echo

	# Runs child process to read first character from stdin.
	ans=$(head --bytes=1)
	stty "$arc"
	trap base_sig_cleanup TERM

	# Adds the new line before any printing to compensate the question without a
	# new line.
	printf \\n
	log Killing watchdog kid "$kid".
	kill "$kid"

	# Command wait could return an error code, temporarily disables exit on
	# error.
	set +o errexit
	wait "$kid" 2>/dev/null
	set -o errexit
	printf %s "$ans" | grep -i -q ^y || { log Stop working.; exit 0;}
	log Continue working.
}

# Downloads a video from YouTube.
ytda() {
	yt-dlp \
		--output "%(uploader)s-%(upload_date)s-%(title)s.%(ext)s" \
		--format bestvideo+bestaudio \
		--merge-output-format mp4 \
		--add-metadata \
		"$@" &&
		renamr -a
}

# Private functions have prefix base_, they are used locally.

base_bye() {
	log "$BASE_IAM $$ says bye after $(base_duration "$BASE_BEG")."
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
	find "$BASE_WIP/../$BASE_IAM".* -name "pid" -exec cat {} \; > "$pip" &
	while read -r pro; do
		kill -0 "$pro" >/dev/null 2>&1 && ins=$((ins+1))
	done < "$pip"

	# My instance is running.
	echo $$ > "$pid"

	# Asks permission in case of multiple instances.
	[ $ins -ne 0 ] || return 0
	if [ $ins -gt 1 ]; then
		end=es
		vrb=are
	else
		end=e
		vrb=is
	fi
	yes_to_continue $ins instanc$end of "$BASE_IAM" $vrb running, continue?
}

# General exit handler, it is called on EXIT. Any first parameter means no
# exit.
base_cleanup() {
	local \
		err=$? \
		log="$BASE_WIP/../$BASE_IAM-log"
	trap - HUP EXIT INT QUIT TERM

	# Keeps logs of last finished instance. Calls base_bye right before log
	# moving or log deleting.
	if is_writable "$log" >/dev/null; then
		base_bye
		cp -f "$BASE_WIP/log" "$log"
	else
		base_bye
	fi
	rm -fr "$BASE_WIP"

	# Parameter expansion defines if the parameter is not set, which means exit.
	if [ -z ${1+x} ]; then
		exit $err
	fi
}

# Prints shellbase usage and exits.
base_display_usage() {
	if var_exists BASE_APP_USAGE >/dev/null; then
		printf %s\\n "$BASE_APP_USAGE"
		return 0
	fi
	cat <<-EOM
		Usage: $BASE_IAM [-e] [-h] [-v] [-w] [-x]

		Arguments:
		  -h, --help        Display this help message.
		  -q, --quiet       Hides information and warning logs.
		  -v, --version     Display version number.
		  -w, --warranty    Echoes warranty statement to stdout.
		  -x, --execute     Echoes every command before execution.
EOM
}

# Prints shellbase version and exits.
base_display_version() {
	printf shellbase\ %s\\n "$BASE_VERSION"
	var_exists BASE_APP_VERSION >/dev/null || return 0
	printf %s\ %s\\n "$BASE_IAM" "$BASE_APP_VERSION"
}

# Prints shellbase warranty.
base_display_warranty() {
	if var_exists BASE_APP_WARRANTY >/dev/null; then
		printf %s\\n "$BASE_APP_WARRANTY"
		return 0
	fi
	cat <<-EOM
		Copyright 2020-2023 David Rabkin

		Permission to use, copy, modify, and/or distribute this software for any
		purpose with or without fee is hereby granted.

		THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
		WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
		MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
		ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
		WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
		ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
		OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
EOM
}

# Calculates duration time for report. The first parameter is a start time.
# 86400 seconds in a day, 3600 seconds in an hour, 60 seconds in a minute.
base_duration() {
	local \
		day \
		dur \
		hou \
		min \
		sec
	dur="$(($(date +%s)-$1))"
	day="$(base_time_title $((dur/86400)) day)"
	hou="$(base_time_title $((dur%86400/3600)) hour)"
	min="$(base_time_title $((dur%86400%3600/60)) minute)"
	sec="$(base_time_title $((dur%60)) second)"
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

base_hi() {
	log "$BASE_IAM $$" says hi.
}

# Defines if shellbase is running in interactive mode.
base_is_interactive() {
	case "$-" in *i*) return 0; esac
	return 1
}

# Loops through the function arguments before any log. Handles only arguments
# with 'do and exit' logic.
base_main() {
	local arg use=false ver=false war=false
	for arg do
		case "$arg" in
			-h|--help) use=true;;
			-v|--version) ver=true;;
			-w|--warranty) war=true;;
		esac
	done

	# Sets global variables. Busybox implementation of mktemp requires six Xs.
	# 'date', 'basename' and 'mktemp' do not return errors.
	BASE_BEG="$(date +%s)"
	BASE_IAM="$(basename -- "$0")"
	BASE_IAM="${BASE_IAM%.*}"
	BASE_WIP="$(mktemp -d /tmp/"$BASE_IAM.XXXXXX")"
	BASE_LOG="$BASE_WIP"/log
	readonly \
		BASE_BEG \
		BASE_IAM \
		BASE_LOG \
		BASE_WIP
	base_hi

	# Handles signals, see more:
	#  https://mywiki.wooledge.org/SignalTrap
	trap base_cleanup EXIT
	trap base_sig_cleanup HUP INT QUIT TERM

	# Detects previously ran processes with the same name. If finds asks to
	# continue.
	base_check_instances

	# The usage has higher priority over version in case both options are set.
	[ false = $use ] || { base_display_usage; exit 0;}
	[ false = $ver ] || { base_display_version; exit 0;}
	[ false = $war ] || { base_display_warranty; exit 0;}
}

# Adds vertical borders. Double quates are needed.
base_prettytable_prettify() {
	cat - | sed "s/^/|/;s/\$/	/;s/	/	|/g"
}

# Adds horisontal line with colums separator. The input parameter is a number
# of columns.
base_prettytable_separator() {
	local i="$1"
	printf +
	while [ "$i" -gt 1 ]; do
		printf \\t+
		i=$((i-1))
	done
	printf '\t+\n'
}

# Prevents double cleanup, see more:
#  https://unix.stackexchange.com/questions/57940/trap-int-term-exit-really-necessary
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
			[ -n "$1" ] && cnt=$((cnt+1))
			;;
		2)
			[ -n "$1" ] && cnt=$((cnt+1))
			[ -n "$2" ] && cnt=$((cnt+1))
			;;
		3)
			[ -n "$1" ] && cnt=$((cnt+1))
			[ -n "$2" ] && cnt=$((cnt+1))
			[ -n "$3" ] && cnt=$((cnt+1))
			;;
		*)
			loge Wrong param number "$#".
			return 0
			;;
	esac
	case "$cnt" in
		0) ;;
		1) printf ' and ';;
		2|3) printf ', ';;
		*) loge Wrong number "$cnt".;;
	esac
}

# Formats time titles, the first parameter is a number, the second parameter is
# a time title.
base_time_title() {
	case "$1" in
		0) printf '';;
		1) printf %d\ %s "$1" "$2";;
		*) printf %d\ %ss "$1" "$2";;
	esac
}

# Truncates log file in case it is more than 10MB. Do not return in
# functions that are called by signal trap.
base_truncate() {
	[ -w "$BASE_LOG" ] || return 0
	[ "$(wc -c <"$BASE_LOG")" -gt 10485760 ] || return 0
	: > "$BASE_LOG"
	log "$BASE_LOG" is truncated.
}

# Adds log string to the log file.
base_write_to_file() {
	base_truncate
	printf %s\\n "$*" >> "$BASE_LOG"
}

# Starting point. Stops right away if it has ran in interactive mode.
base_is_interactive && return 0
set -o errexit
set -o nounset

# Loops through command line arguments of the script. Handles only arguments
# with set-and-go logic.
for arg do
	shift
	case "$arg" in
		-q|--quiet) BASE_QUIET=true;;
		-x|--execute) set -x;;
		*) set -- "$@" "$arg";;  # Sets back any unused args.
	esac
done
unset arg
readonly BASE_QUIET BASE_VERSION
base_main "$@"
