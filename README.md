# Shellbase [![Linters](https://github.com/rdavid/shellbase/actions/workflows/lint.yml/badge.svg)](https://github.com/rdavid/shellbase/actions/workflows/lint.yml) [![Hits-of-Code](https://hitsofcode.com/github/rdavid/shellbase?branch=master&label=hits-of-code)](https://hitsofcode.com/view/github/rdavid/shellbase?branch=master) ![GitHub all releases](https://img.shields.io/github/downloads/rdavid/shellbase/total?color=informational) [![License](https://img.shields.io/badge/license-0BSD-informational)](https://github.com/rdavid/shellbase/blob/master/LICENSE)
General framework for Unix shell scripts.

* [About](#about)
* [Install](#install)
* [Test](#test)
* [License](#license)

## About
Hi, I'm [David Rabkin](http://cv.rabkin.co.il).

`shellbase` is a general framework for Unix shell scripts. The framework is
mostly POSIX-compliant. It provides multiple services: public functions
(logger, validation), signals handlers, garbage collection, multiple instances.
It asks for a permission to continue if multiple running instances of a same
script are detected.

`shellbase` defines global variables and functions. All functions without
`base_` prefix are public and could be used by clients. The public functions
are, in alphabetical order:
`aud_only`, `be_root`, `be_user`, `cheat`, `cmd_exists`, `echo`, `die`,
`file_exists`, `grbt`, `heic2jpg`, `inside`, `is_empty`, `is_readable`,
`is_solid`, `is_writable`, `log`, `loge`, `logw`, `pdf2jpg`, `pdf2png`,
`prettytable`, `semver`, `timestamp`, `to_log`, `to_loge`, `to_lower`,
`url_exists`, `user_exists`, `validate_cmd`, `validate_var`, `var_exists`,
`ver_ge`, `vid2aud`, `yes_to_continue`, `ytda`.

Global variables have `BASE_` prefix and clients could use them. Clients should
place all temporaly files under `$BASE_WIP`. All functions started with `base_`
prefix are internal and should not be used by clients. All names are in
alphabetical order.

See [`toolbox`](https://github.com/rdavid/toolbox) as an example.

## Install
The artifact is a single non-executable [text
file](https://github.com/rdavid/shellbase/blob/master/lib/base.sh). Install the
file from the repository:
```sh
git clone git@github.com:rdavid/shellbase.git &&
	./shellbase/install
```
Install the file from released version directly. Some OS demands
administrative rights to install to `/usr/local/bin`, use `sudo` or `doas`
before `tar`:
```sh
REL=0.9.20230102
SRC=https://github.com/rdavid/shellbase/archive/refs/tags/v$REL.tar.gz
curl --location --silent $SRC |
	tar \
		--directory /usr/local/bin \
		--extract \
		--gzip \
		--strip-components=2 \
		shellbase-$REL/lib/base.sh
```
Make sure `/usr/local/bin` is in your `PATH`. Then your script can use
`shellbase`:
```sh
#!/bin/sh
# shellcheck disable=SC1091 # File not following.
. base.sh
log I\'m using the shellbase.
```
You can try `shellbase` without installation:
```sh
#!/bin/sh
REL=0.9.20230102
SRC=https://github.com/rdavid/shellbase/archive/refs/tags/v$REL.tar.gz
eval "$(
	curl --location --silent $SRC |
		tar \
			--extract \
			--gzip \
			--to-stdout \
			shellbase-$REL/lib/base.sh
)"
log I\'m using the shellbase.
```
`prettytable` example:
```sh
#!/bin/sh
# shellcheck disable=SC1091 # File not following.
. base.sh
{
	printf 'ID\tNAME\tTITLE\n'
	printf '123456789\tJohn Foo\tDirector\n'
	printf '12\tMike Bar\tEngineer\n'
} | prettytable
```
Output:
```
20220831-01:07:40 I prettytable 33704 says hi.
20220831-01:07:40 I +-----------+----------+----------+
20220831-01:07:40 I |ID         |NAME      |TITLE     |
20220831-01:07:40 I +-----------+----------+----------+
20220831-01:07:40 I |123456789  |John Foo  |Director  |
20220831-01:07:40 I |12         |Mike Bar  |Engineer  |
20220831-01:07:41 I +-----------+----------+----------+
20220831-01:07:41 I prettytable 33704 says bye after 1 second.
```
## Test
The project uses Daniel J. Bernstein's (aka, djb)
[build system](http://cr.yp.to/redo.html). You can install Sergey Matveev's
[`goredo`](http://www.goredo.cypherpunks.ru/Install.html) implementation.

Run [`shellcheck`](https://github.com/koalaman/shellcheck) on sources by
`redo shellcheck`, run tests by `redo test`, run tests in multiple environments
in containers by `redo test_container`. It uses
[`goredoer`](https://github.com/rdavid/goredoer) to build
[`goredo`](http://www.goredo.cypherpunks.ru/Install.html).

## License
`shellbase` is copyright [David Rabkin](http://cv.rabkin.co.il) and available
under a
[Zero-Clause BSD license](https://github.com/rdavid/shellbase/blob/master/LICENSE).
