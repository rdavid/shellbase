# Shellbase [![Hits-of-Code](https://hitsofcode.com/github/rdavid/shellbase?branch=master)](https://hitsofcode.com/view/github/rdavid/shellbase?branch=master) [![License](https://img.shields.io/badge/license-0BSD-green)](https://github.com/rdavid/shellbase/blob/master/LICENSE)
General framework for Unix shell scripts.

* [About](#about)
* [License](#license)

## About
Hi, I'm [David Rabkin](http://cv.rabkin.co.il).

`shellbase` is general framework for Unix shell scripts. It provides multiple
services: public functions (logger, validation), signals handlers, garbage
collection, multiple instances. It asks for a permission to continue if multiple
running instances of a same script are detected.

`shellbase` defines global variables and functions. All functions without
`base_` prefix are API and should be used by clients. API functions are:
`be_root`, `be_user`, `die`, `file_exists`, `is_empty`, `is_readable`,
`is_writable`, `log`, `loge`, `logw`, `url_exists`, `validate_cmd`,
`validate_var`, `var_exists`, `yes_to_continue`. Global variables have `BASE_`
prefix and clients could use them. Clients should place all temporaly files
under `$BASE_LCK`. All functions started with `base_` prefix are internal and
should not be used by clients.

Run `shellcheck` on sources by `redo`, run tests by `redo test`. Install
[Daniel J. Bernstein's redo build system](http://cr.yp.to/redo.html) program by:
`brew install redo`.

Or run tests in multiple environments in containers:
```
./ctest.sh --verbose
```

See [Toolbox project](https://github.com/rdavid/toolbox) as an example.

## License
`shellbase` is copyright [David Rabkin](http://cv.rabkin.co.il) and available
under a [Zero-Clause BSD license](https://github.com/rdavid/shellbase/blob/master/LICENSE).
