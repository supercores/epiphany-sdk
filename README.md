# Epiphany SDK Build and Install Package

[![Build Status](https://travis-ci.org/supercores/epiphany-sdk.svg?branch=2019.8.gcc5)](https://travis-ci.org/supercores/epiphany-sdk)
[![Build Status](https://travis-ci.org/supercores/epiphany-sdk.svg?branch=2019.8.gcc8)](https://travis-ci.org/supercores/epiphany-sdk)

## Start Here

This repository is the main poject for building and installing
the Epiphany SDK toolchain.

Check out the release branch to build.

To cross compile execute:

```
sdk/build-epiphany-sdk.sh -c arm-linux-gnueabihf
```

## Release information

Releases are versioned according to the following abstraction with unique
branches created per release.

 * MAJOR version = the current year
 * MINOR version = the current month
 * PATCH version = for multiple releases per month (if required)
 * GCC version   = the gcc major version (currently support gcc5 and gcc8)

To build a specefic release checkout the particular branch.

## Disclaimer

This package is still in development process. There is no guarantee for
backward compatibility of future releases.

## Copyright note:

This file is part of the Epiphany Software Development Kit.

Copyright (C) 2019 SuperCores project.  
Copyright (C) 2013 Adapteva, Inc.  
Contributed by Yaniv Sapir <support@adapteva.com>  

This package is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License (or the GNU
Lesser General Public License where explicitly noted) as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see the file COPYING).  If not, see
<http://www.gnu.org/licenses/>.

