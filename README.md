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
|GET| /api/v1/floors||[FloorInfo]||✓|✓|✓|
|GET| /api/v1/floors/:id||Floor|fetch latest version|✓|✓|✓|
|GET| /api/v1/floors/:id/edit||Floor|fetch latest unpublished version||✓|✓|
|PUT| /api/v1/floors/:id/edit|Floor||update latest unpublished version||✓|✓|
|POST| /api/v1/floors/:id|||publish latest unpublished version|||✓|
|DELETE| /api/v1/floors/:id||||||✓|
|PUT| /api/v1/images/:id|Image|||||✓|

<!-- 
|GET| /api/v1/floors/:id/versions||||✓|✓|✓|
|GET| /api/v1/floors/:id/version/:version||||✓|✓|✓| 
-->

### Types
|Type|Structure|
|:--|:--|
|User| { id : UUID, name : Person.name, role : Role, personId : Person.id } |
|Floor| { id : UUID, version : int, name : string, image? : URL, realSize? : (int, int), equipments : [ Equipment ], public : boolean, publishedBy? : User.id, publishedAt? : Date } |
|Equipment| { id : UUID, name : string, size : (int, int), color : Color, personId? : Person.id } |
|Prototype| { id : UUID, name : string, size : (int, int), color : Color } |
|Image| binary |
|SearchResult| [(Equipment, string)] |
|Person| { id : string, name : string, org : string, tel? : string, mail? : string, image? : URL } |
|Role| "admin" "general" |
|Color| string |
|UUID| string |
|Date| int |
|URL| string |

### Tables

#### User
|id|pass|role|personId|
|:--|:--|:--|:--|
|string|string|string|Person.id|

#### Floor
|id*|version*|name|image|width|height|realWidth|realHeight|public|updateBy|updateAt|
|:--|:--|:--|:--|:--|:--|:--|:--|:--|:--|:--|
|string|string|string|string|int|int|int|int|bool|User.id|bigint|

#### Equipment
|id|name|width|height|color|personId|floorId|
|:--|:--|:--|:--|:--|:--|:--|
|string|string|int|int|string|Person.id|Floor.id|

#### Person
|id|name|org|tel|mail|image|
|:--|:--|:--|:--|:--|:--|
|string|string|string|string|string|string|

## Development

### Requirement

You need to have [Elm](http://elm-lang.org/) (== 0.17) and [Node.js](https://nodejs.org/) (>= 4.0) installed.

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
