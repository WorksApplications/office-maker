Office Maker
----

[![Build Status](https://travis-ci.org/WorksApplications/office-maker.svg)](https://travis-ci.org/WorksApplications/office-maker)

CAUTION: Currently this product is work in progress.

TODO: All of following processes should be replaced by Docker.


### Requirement

You need to have [Elm](http://elm-lang.org/) (>= 0.18) and [Node.js](https://nodejs.org/) (>= 4.0) installed.

### Install Elm

```
# npm install -g elm
```

### Install libraries

```
$ elm-package install
$ npm install
$ cd server
$ npm install
```

### Build

```
$ sh build.sh
```

If `elm-make` fails in Windows, try
```
$ chcp 65001
```
which changes encoding to UTF-8.


### Run server

```
node watch
```

#### debug mode

To debug Elm program, use `--debug` option.

```
node watch --debug
```

## License

[Apache License 2.0](LICENSE)
