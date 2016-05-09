Office Maker (WIP)
----

CAUTION: This product is under construction.

## Routing

|URL|
|:--|
|/|
|/#floorId|
|/#floorId?q=foo|

## REST API

|Method|URL|Req Body|Res Body|Description|Guest|General|Admin|
|:--|:--|:--|:--|:--|:--|:--|:--|
|GET| /api/v1/search/:query||||✓|✓|✓|
|GET| /api/v1/auth||||✓|✓|✓|
|GET| /api/v1/persons||||✓|✓|✓|
|GET| /api/v1/persons/missing||||✓|✓|✓|
|GET| /api/v1/persons/:personId||||✓|✓|✓|
|GET| /api/v1/candidate/:name||||✓|✓|✓|
|GET| /api/v1/prototypes||||✓|✓|✓|
|PUT| /api/v1/prototypes/:id|Prototype|||||✓|
|DELETE| /api/v1/prototypes/:id||||||✓|
|GET| /api/v1/floors||||✓|✓|✓|
|GET| /api/v1/floors/:id|||fetch latest version|✓|✓|✓|
|GET| /api/v1/floors/:id/versions||||✓|✓|✓|
|GET| /api/v1/floors/:id/version/:version||||✓|✓|✓|
|GET| /api/v1/floors/:id/edit|||fetch latest unpublished version||✓|✓|
|PUT| /api/v1/floors/:id/edit|Floor||update latest unpublished version||✓|✓|
|POST| /api/v1/floors/:id|||publish latest unpublished version|||✓|
|DELETE| /api/v1/floors/:id||||||✓|
|PUT| /api/v1/images/:id|Image|||||✓|

### Types
|Type|Structure|
|:--|:--|
|Floor|TODO|
|Prototype|TODO|
|Image|TODO|
|Person|TODO|

## Development

### Requirement

You need to have [Elm](http://elm-lang.org/) (== 0.17) and [Node.js](https://nodejs.org/) installed.

### Install

```
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

### Running tasks with mock server

```
node watch
```

## License

[Apache License 2.0](LICENSE)
