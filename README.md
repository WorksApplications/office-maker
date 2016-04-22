Office Maker (WIP)
----

CAUTION: This product is under construction.

### Routing

|URL|
|:--|
|/|
|/#flooId|
|/#floorId?q=foo|

### REST API

|Method|URL|Req Body|Res Body|Description|Guest|General|Admin|
|:--|:--|:--|:--|:--|:--|:--|:--|
|GET| /api/v1/users||||✓|✓|✓|
|GET| /api/v1/users/missing||||✓|✓|✓|
|GET| /api/v1/user/:user||||✓|✓|✓|
|GET| /api/v1/prototypes||||✓|✓|✓|
|PUT| /api/v1/prototype/:id|Prototype|||||✓|
|DELETE| /api/v1/prototype/:id||||||✓|
|GET| /api/v1/floors||||✓|✓|✓|
|GET| /api/v1/floor/:id|||fetch latest version|✓|✓|✓|
|GET| /api/v1/floor/:id/versions||||✓|✓|✓|
|GET| /api/v1/floor/:id/version/:version||||✓|✓|✓|
|GET| /api/v1/floor/:id/edit|||fetch latest unpublished version||✓|✓|
|PUT| /api/v1/floor/:id/edit|Floor||update latest unpublished version||✓|✓|
|PUSH| /api/v1/floor/:id|||publish latest unpublished version|||✓|
|DELETE| /api/v1/floor/:id||||||✓|
|PUT| /api/v1/image/:id|Image|||||✓|

#### Types
|Type|Structure|
|:--|:--|
|Floor|TODO|
|Prototype|TODO|
|Image|TODO|
|User|TODO|

### Development

If `elm-make` fails in Windows, try
```
chcp 65001
```
which will change encoding to UTF-8.

To build:
```
sh build.sh
```
