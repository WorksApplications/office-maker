Office Maker
----

CAUTION: This product is under construction.

## Routing

|URL|
|:--|
|/|
|/#floorId|
|/?q=foo&edit=#floorId|

## REST API

|Method|URL|Req Body|Res Body|Description|Guest|General|Admin|
|:--|:--|:--|:--|:--|:--|:--|:--|
|GET| /api/v1/search/:query||[SearchResult]||✓|✓|✓|
|GET| /api/v1/auth||User||✓|✓|✓|
|GET| /api/v1/people||[Person]||✓|✓|✓|
|GET| /api/v1/people/:personId||Person||✓|✓|✓|
|GET| /api/v1/candidates/:name||[Person]||✓|✓|✓|
|GET| /api/v1/colors||[Color]||✓|✓|✓|
|GET| /api/v1/prototypes||[Prototype]||✓|✓|✓|
|PUT| /api/v1/prototypes/:id|Prototype|||||✓|
|DELETE| /api/v1/prototypes/:id||||||✓|
|GET| /api/v1/floors||[FloorInfo]||✓|✓|✓|
|GET| /api/v1/floors?all=true||[FloorInfo]||✓|✓|✓|
|GET| /api/v1/floors/:id||Floor|fetch latest version|✓|✓|✓|
|GET| /api/v1/floors/:id?all=true||Floor|fetch latest unpublished version||✓|✓|
|PUT| /api/v1/floors/:id|FloorChange||update latest unpublished version||✓|✓|
|PUT| /api/v1/floors/:id/public|||publish latest unpublished version|||✓|
|PUT| /api/v1/images/:id|Image|||||✓|

<!--
|PUT| /api/v1/colors||[Color]||||✓|
|GET| /api/v1/people/missing||[Person]||✓|✓|✓|
|GET| /api/v1/floors/:id/versions||||✓|✓|✓|
|GET| /api/v1/floors/:id/version/:version||||✓|✓|✓|
|DELETE| /api/v1/floors/:id||||||✓|
-->

### Types

|Type|Structure|
|:--|:--|
|User| { id : UUID, name : Person.name, role : Role, personId : String } |
|Floor| { id : UUID, ord : Int, version : Int, name : String, image? : URL, realSize? : (Int, Int), objects : [ Object ], public : Bool, publishedBy? : User.id, publishedAt? : Date } |
|FloorChange| { id : UUID, ord : Int, version : Int, name : String, image? : URL, realSize? : (Int, Int), add : [ Object ], modify : [ (Object, Object) ], delete : [ Object ], public : Bool, publishedBy? : User.id, publishedAt? : Date } |
|Object| { id : UUID, type: String, name : String, size : (Int, Int), color : String, fontSize : Float, shape : String, personId? : String } |
|Prototype| { id : UUID, name : String, size : (Int, Int), color : String } |
|Image| Binary |
|SearchResult| [(Object, String)] |
|Person| { id : String, name : String, org : String, tel? : String, mail? : String, image? : URL } |
|Role| "admin" "general" |
|Color| { id : String, ord : Int, type : String, color : String } |
|UUID| String |
|Date| Int |
|URL| String |

### Server Implementations

There is only one server implementation which is made for debugging.See [here](./test/server/README.md).


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
