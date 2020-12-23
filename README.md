# Shellbase
General framework for POSIX shell scripts

[![Hits-of-Code](https://hitsofcode.com/github/rdavid/shellbase?branch=master)](https://hitsofcode.com/view/github/rdavid/shellbase?branch=master)
[![License](https://img.shields.io/badge/license-0BSD-green)](https://github.com/rdavid/shellbase/blob/master/LICENSE)

* [About](#about)
* [License](#license)

## About
Hi, I'm [David Rabkin](http://davi.drabk.in).

`shellbase` is general framework for POSIX shell scripts. It provides multiple
services: functions (`be_root`, `die`, `log`, `validate`, `yes_to_continue`),
signals handlers, garbage collection, multiple instances. It asks for a
permission to continue if multiple running instances of a same script are
detected.

`shellbase` defines global variables and functions. All functions without
`base_` prefix are API and should be used by clients. API functions are: `log`,
`loge`, `die`, `validate`, `be_root`, `yes_to_continue`. Global variables has
`BASE_` prefix and clients could use them. Clients should place all temporaly
files under `$BASE_LCK`. All functions started with `base_` prefix are internal
and should not be used by clients.

See [Toolbox project](https://github.com/rdavid/toolbox) as an example.

## License
`shellbase` is copyright [David Rabkin](http://davi.drabk.in) and available
under a [Zero-Clause BSD license](https://github.com/rdavid/shellbase/blob/master/LICENSE).
