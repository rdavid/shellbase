# Shellbase [![Hits-of-Code](https://hitsofcode.com/github/rdavid/shellbase?branch=master)](https://hitsofcode.com/view/github/rdavid/shellbase?branch=master) [![License](https://img.shields.io/badge/license-0BSD-green)](https://github.com/rdavid/shellbase/blob/master/LICENSE)
General framework for Unix shell scripts.

* [About](#about)
* [Install](#install)
* [Test](#test)
* [License](#license)

## About
Hi, I'm [David Rabkin](http://cv.rabkin.co.il).

`shellbase` is general framework for Unix shell scripts. It provides multiple
services: public functions (logger, validation), signals handlers, garbage
collection, multiple instances. It asks for a permission to continue if
multiple running instances of a same script are detected.

`shellbase` defines global variables and functions. All functions without
`base_` prefix are API and should be used by clients. API functions are:
`be_root`, `be_user`, `cmd_exists`, `echo`, `die`, `file_exists`, `grbt`,
`heic2jpg`, `inside`, `is_empty`, `is_readable`, `is_solid`, `is_writable`,
`log`, `loge`, `logw`, `prettytable`, `pingo`, `semver`, `timestamp`, `to_log`,
`to_loge`, `to_lower`, `url_exists`, `user_exists`, `validate_cmd`,
`validate_var`, `var_exists`, `yes_to_continue`, `ytda`.

Global variables have `BASE_` prefix and clients could use them. Clients should
place all temporaly files under `$BASE_WIP`. All functions started with `base_`
prefix are internal and should not be used by clients.

See [`toolbox`](https://github.com/rdavid/toolbox) as an example.

## Install
The artifact is a single non-executable [text
file](https://github.com/rdavid/shellbase/blob/master/lib/base.sh). Install the
file from the repository:
```sh
git clone https://github.com/rdavid/shellbase.git &&
	./shellbase/install
```
Install the file from released version directly. Some OS demands
administrative rights to install to `/usr/local/bin/`, use `sudo` or `doas`
before `curl`:
```sh
DST=/usr/local/bin/base.sh
REL=v0.9.20221213
SRC=https://github.com/rdavid/shellbase/releases/download/$REL/base.sh
curl --location --output $DST --silent $SRC
```
Make sure `/usr/local/bin/` is in your `PATH`. Then your script can use
`shellbase`:
```sh
#!/bin/sh
. base.sh
log I\'m using shellbase.
```
You can try `shellbase` without installation:
```sh
#!/bin/sh
REL=v0.9.20221213
SRC=https://github.com/rdavid/shellbase/releases/download/$REL/base.sh
eval "$(curl --location --silent $SRC)"
log I\'m using shellbase.
```
`prettytable` example:
```sh
#!/bin/sh
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
[goredo implementation](http://www.goredo.cypherpunks.ru/Install.html).

Run `shellcheck` on sources by `redo shellcheck`, run tests by `redo test`, run
tests in multiple environments in containers by `redo test_container`.

## License
`shellbase` is copyright [David Rabkin](http://cv.rabkin.co.il) and available
under a
[Zero-Clause BSD license](https://github.com/rdavid/shellbase/blob/master/LICENSE).
