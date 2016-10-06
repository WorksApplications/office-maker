Office Maker
----

CAUTION: This product is under construction.

### Server Implementations

There is only one server implementation which is made for debugging.See [here](./server/README.md).


## Development

### Requirement

You need to have [Elm](http://elm-lang.org/) (>= 0.17) and [Node.js](https://nodejs.org/) (>= 4.0) installed.

### Install

```
elm-package install
npm install
cd server
npm install
```

### Build

```
sh build.sh
```

If `elm-make` fails in Windows, try
```
chcp 65001
```
which will change encoding to UTF-8.


### Run server

See [server's document](./server/README.md).


### Run server for development

```
node watch
```

### Test

```
npm test
```

## License

[Apache License 2.0](LICENSE)
