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
`be_root`, `be_user`, `die`, `file_exists`, `is_empty`, `is_readable`,
`is_writable`, `log`, `loge`, `logw`, `url_exists`, `validate_cmd`,
`validate_var`, `var_exists`, `yes_to_continue`. Global variables have `BASE_`
prefix and clients could use them. Clients should place all temporaly files
under `$BASE_LCK`. All functions started with `base_` prefix are internal and
should not be used by clients.

## Install
Make sure `/usr/local/bin` is in your `PATH`.

    wget \
      https://github.com/rdavid/shellbase/releases/download/v0.9.20220516/base \
      --output-document /usr/local/bin/shellbase

Install [Daniel J. Bernstein's redo build system](http://cr.yp.to/redo.html)
program by: `brew install goredo`.

## Test

    git clone https://github.com/rdavid/shellbase.git

Run `shellcheck` on sources by `redo`, run tests by `redo test`, run tests in
multiple environments in containers by `redo test_container`.

See [Toolbox project](https://github.com/rdavid/toolbox) as an example.

## License
`shellbase` is copyright [David Rabkin](http://cv.rabkin.co.il) and available
under a [Zero-Clause BSD license](https://github.com/rdavid/shellbase/blob/master/LICENSE).
