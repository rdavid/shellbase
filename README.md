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
`be_root`, `be_user`, `cmd_exists`, `die`, `file_exists`, `is_empty`,
`is_readable`, `is_writable`, `log`, `loge`, `logw`, `prettytable`,
`timestamp`, `to_log`, `to_loge`, `url_exists`, `user_exists`, `validate_cmd`,
`validate_var`, `var_exists`, `yes_to_continue`. Global variables have `BASE_`
prefix and clients could use them. Clients should place all temporaly files
under `$BASE_LCK`. All functions started with `base_` prefix are internal and
should not be used by clients.

See [Toolbox project](https://github.com/rdavid/toolbox) as an example.

## Install
The artifact is a single non-executable [text
file](https://github.com/rdavid/shellbase/blob/master/inc/base). Install the
file from the repository:

    git clone https://github.com/rdavid/shellbase.git &&
    	shellbase/install.sh

Install the file from released version directly:

    TAG=v0.9.20220809 \
    wget \
    	https://github.com/rdavid/shellbase/releases/download/$TAG/base \
    	--output-document /usr/local/bin/shellbase

Make sure `/usr/local/bin` is in your `PATH`. Then your script can use
`shellbase`, e.g. `foobar.sh`:

    #!/bin/sh -eu
    . shellbase
    log I\'m using shellbase!

You can try shellbase without installation, e.g. `foobar.sh`:

    #!/bin/sh -eu
    TAG=v0.9.20220809
    URL=https://github.com/rdavid/shellbase/releases/download/$TAG/base
    eval \
    	"$(
    		wget $URL \
    			--output-document - \
    			--quiet \
    	)"
    log I\'m using shellbase!

Prettytable example:

    #!/bin/sh -eu
    . shellbase
    {
    	printf 'ID\tNAME\tTITLE\n'
    	printf '123456789\tJohn Foo\tDirector\n'
    	printf '12\tMike Bar\tEngineer\n'
    } | prettytable

Output:

    +-----------+----------+----------+
    |ID         |NAME      |TITLE     |
    +-----------+----------+----------+
    |123456789  |John Foo  |Director  |
    |12         |Mike Bar  |Engineer  |
    +-----------+----------+----------+

## Test
The project uses Daniel J. Bernstein's (aka, djb)
[build system](http://cr.yp.to/redo.html). You can install Sergey Matveev's
[goredo implementation](http://www.goredo.cypherpunks.ru/Install.html).

Run `shellcheck` on sources by `redo`, run tests by `redo test`, run tests in
multiple environments in containers by `redo test_container`.

## License
`shellbase` is copyright [David Rabkin](http://cv.rabkin.co.il) and available
under a [Zero-Clause BSD license](https://github.com/rdavid/shellbase/blob/master/LICENSE).
