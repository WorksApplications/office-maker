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
|GET| /api/v1/search/:query||[SearchResult]||✓|✓|✓|
|GET| /api/v1/auth||||✓|✓|✓|
|GET| /api/v1/people||[Person]||✓|✓|✓|
|GET| /api/v1/people/missing||[Person]||✓|✓|✓|
|GET| /api/v1/people/:personId||Person||✓|✓|✓|
|GET| /api/v1/candidate/:name||[Person]||✓|✓|✓|
|GET| /api/v1/colors||[Color]||✓|✓|✓|
|GET| /api/v1/prototypes||[Prototype]||✓|✓|✓|
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
|User| { id : UUID, name : string, role : Role, personId? : string } |
|Floor| { id : UUID, name : string, image : string, realSize? : (int, int), equipments : [ Equipment ], public : boolean, publishedBy? : string, publishedAt? : Date } |
|Equipment| { id : UUID, name : string, size : (int, int), color : Color, userId? : string } |
|Prototype| { id : UUID, name : string, size : (int, int), color : Color } |
|Image| binary |
|SearchResult| [(Equipment, string)] |
|Person| { id : string, name : string, org : string, tel? : string, mail? : string } |
|Role| "admin" "general" |
|Color| string |
|UUID| string |
|Date| int |

## Development

### Requirement

You need to have [Elm](http://elm-lang.org/) (== 0.17) and [Node.js](https://nodejs.org/) installed.

### Install

```
elm-package install
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

### Test

```
npm test
```

## License

[Apache License 2.0](LICENSE)
