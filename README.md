Office Maker
----

CAUTION: This product is under construction.

## Routing

|URL|
|:--|
|/|
|/login|
|/#floorId|
|/?q=foo&edit=#floorId|

## REST API

|Method|URL|Req Body|Res Body|Description|Guest|General|Admin|
|:--|:--|:--|:--|:--|:--|:--|:--|
|GET| /api/1/search/:query||[SearchResult]||✓|✓|✓|
|GET| /api/1/auth||User||✓|✓|✓|
|GET| /api/1/people||[Person]||✓|✓|✓|
|GET| /api/1/people/:personId||Person||✓|✓|✓|
|GET| /api/1/candidates/:name||[Person]||✓|✓|✓|
|GET| /api/1/colors||[Color]||✓|✓|✓|
|GET| /api/1/prototypes||[Prototype]||✓|✓|✓|
|PUT| /api/1/prototypes/:id|Prototype|||||✓|
|DELETE| /api/1/prototypes/:id||||||✓|
|GET| /api/1/floors||[FloorInfo]||✓|✓|✓|
|GET| /api/1/floors?all=true||[FloorInfo]||✓|✓|✓|
|GET| /api/1/floors/:id||Floor|fetch latest version|✓|✓|✓|
|GET| /api/1/floors/:id?all=true||Floor|fetch latest unpublished version||✓|✓|
|PUT| /api/1/floors/:id|FloorChange|Floor|update latest unpublished version||✓|✓|
|PUT| /api/1/floors/:id/public||Floor|publish latest unpublished version|||✓|
|PUT| /api/1/images/:id|Image|||||✓|

<!--
|PUT| /api/1/colors||[Color]||||✓|
|GET| /api/1/people/missing||[Person]||✓|✓|✓|
|GET| /api/1/floors/:id/versions||||✓|✓|✓|
|GET| /api/1/floors/:id/version/:version||||✓|✓|✓|
|DELETE| /api/1/floors/:id||||||✓|
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
|Person| { id : String, name : String, post : String, tel? : String, mail? : String, image? : URL } |
|Role| "admin" "general" |
|Color| { id : String, ord : Int, type : String, color : String } |
|UUID| String |
|Date| Int |
|URL| String |

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
