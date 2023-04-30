# Shellbase

[![linters](https://github.com/rdavid/shellbase/actions/workflows/lint.yml/badge.svg)](https://github.com/rdavid/shellbase/actions/workflows/lint.yml)
[![hits of code](https://hitsofcode.com/github/rdavid/shellbase?branch=master&label=hits%20of%20code)](https://hitsofcode.com/view/github/rdavid/shellbase?branch=master)
![downloads](https://img.shields.io/github/downloads/rdavid/shellbase/total?color=blue&labelColor=gray&logo=singlestore&logoColor=lightgray&style=flat)
[![release)](https://img.shields.io/github/v/release/rdavid/shellbase?color=blue&label=%20&logo=semver&logoColor=white&style=flat)](https://github.com/rdavid/shellbase/releases)
[![license](https://img.shields.io/github/license/rdavid/shellbase?color=blue&labelColor=gray&logo=freebsd&logoColor=lightgray&style=flat)](https://github.com/rdavid/shellbase/blob/master/LICENSE)

* [About](#about)
* [Install](#install)
* [Test](#test)
* [License](#license)

## About

`shellbase` is the general framework for Unix shell scripts. The framework is
mostly POSIX-compliant. It provides multiple services: public functions
(logger, validation), signals handlers, garbage collection, multiple instances.
It asks for a permission to continue if multiple running instances of a same
script are detected.

`shellbase` defines global variables and functions. All functions without
`base_` prefix are public and could be used by clients. The public functions
are, in alphabetical order:
[`aud_only`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L52),
[`beroot`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L69),
[`beuser`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L74),
[`cheat`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L85),
[`cmd_exists`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L91),
[`die`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L105),
[`echo`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L113),
[`file_exists`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L131),
[`grbt`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L146),
[`heic2jpg`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L156),
[`inside`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L170),
[`isempty`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L178),
[`isfunc`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L192),
[`isreadable`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L200),
[`issolid`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L216),
[`iswritable`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L245),
[`log`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L269),
[`loge`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L278),
[`logw`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L285),
[`pdf2jpg`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L295),
[`pdf2png`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L304),
[`prettytable`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L327),
[`prettyuptime`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L352),
[`realdir`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L370),
[`realpath`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L379),
[`semver`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L391),
[`timestamp`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L406),
[`tolog`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L422),
[`tologe`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L428),
[`tolower`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L434),
[`tsout`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L439),
[`url_exists`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L448),
[`user_exists`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L473),
[`validate_cmd`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L489),
[`validate_var`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L496),
[`var_exists`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L503),
[`ver_ge`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L524),
[`vid2aud`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L529),
[`yes_to_continue`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L544),
[`ytda`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L598).

Global variables have `BASE_` prefix and clients could use them. Clients should
place all temporaly files under `$BASE_WIP`. All functions started with `base_`
prefix are internal and should not be used by clients. All names are in
alphabetical order.

See [`dotfiles`](https://github.com/rdavid/dotfiles),
[`gento`](https://github.com/rdavid/gento) and
[`toolbox`](https://github.com/rdavid/toolbox) as examples.

## Install

The artifact is a single non-executable POSIX-compliant shell script file
[`base.sh`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh).
Install the file from the repository:

```sh
git clone git@github.com:rdavid/shellbase.git &&
  ./shellbase/app/install
```

Install the file from the released version. Some OS demands
administrative rights to install to `/usr/local/bin`, use `sudo` or `doas`
before `tar`:

```sh
REL=0.9.20230405
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
REL=0.9.20230405
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

[`prettytable`](https://github.com/rdavid/shellbase/blob/master/lib/base.sh#L325)
example:

```sh
. base.sh
{
  printf 'ID\tNAME\tTITLE\n'
  printf '123456789\tJohn Foo\tDirector\n'
  printf '12\tMike Bar\tEngineer\n'
} | prettytable
```

Output:

```sh
+-----------+----------+----------+
|ID         |NAME      |TITLE     |
+-----------+----------+----------+
|123456789  |John Foo  |Director  |
|12         |Mike Bar  |Engineer  |
+-----------+----------+----------+
```

## Test

The project uses Daniel J. Bernstein's (aka, djb) build system
[`redo`](http://cr.yp.to/redo.html). You can install Sergey Matveev's
[`goredo`](http://www.goredo.cypherpunks.ru/Install.html) implementation.

`redo lint` runs the following linters on the source files:

* [`checkmake`](https://github.com/mrtazz/checkmake)
* [`hadolint`](https://github.com/hadolint/hadolint)
* [`markdownlint`](https://github.com/igorshubovych/markdownlint-cli)
* [`shellcheck`](https://github.com/koalaman/shellcheck)
* [`shfmt`](https://github.com/mvdan/sh)
* [`yamllint`](https://github.com/adrienverge/yamllint)

`redo test` runs unit tests in installed shells, `redo test_container` runs the
tests in multiple shells in multiple containers. It uses
[`goredoer`](https://github.com/rdavid/goredoer) to build
[`goredo`](http://www.goredo.cypherpunks.ru/Install.html).

## License

`shellbase` is copyright [David Rabkin](http://cv.rabkin.co.il) and available
under a
[Zero-Clause BSD license](https://github.com/rdavid/shellbase/blob/master/LICENSE).
