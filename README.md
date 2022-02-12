# Shellbase
General framework for Unix shell scripts.

[![Hits-of-Code](https://hitsofcode.com/github/rdavid/shellbase?branch=master)](https://hitsofcode.com/view/github/rdavid/shellbase?branch=master)
[![License](https://img.shields.io/badge/license-0BSD-green)](https://github.com/rdavid/shellbase/blob/master/LICENSE)

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
`be_root`, `bye`, `file_exists`, `is_directory_empty`, `log`, `loge`, `logw`,
`validate_cmd`, `validate_var`, `yes_to_continue`. Global variables have
`BASE_` prefix and clients could use them. Clients should place all temporaly
files under `$BASE_LCK`. All functions started with `base_` prefix are internal
and should not be used by clients.

See [Toolbox project](https://github.com/rdavid/toolbox) as an example.

## License
`shellbase` is copyright [David Rabkin](http://cv.rabkin.co.il) and available
under a [Zero-Clause BSD license](https://github.com/rdavid/shellbase/blob/master/LICENSE).
