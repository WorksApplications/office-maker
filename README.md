Office Maker
====

[![Build Status](https://travis-ci.org/WorksApplications/office-maker.svg)](https://travis-ci.org/WorksApplications/office-maker)

CAUTION: Currently this product is work in progress.


## Requirement

1. [Elm](http://elm-lang.org/) (>= 0.18)
2. [Node.js](https://nodejs.org/) (>= 4.0)
3. MySQL
4. Static file server (nginx or httpd)

* To develop: all
* To run: 2, 3 and 4


## Build

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

## API Server Settings

`cd server` first.


### Initialize

If this is the first time to set up, execute following.

* Create config.json
* Initialize DB

```
$ sh initialize.sh
```

### Configuration

Edit `config.json`. Bold properties are essential to work with various environment.

|name||
|:--|:--|
|mysql.host||
|mysql.user||
|mysql.pass||
|title|This name is used by header.|
|**accountServiceRoot**|URL of account service. http://xxx.xxx.xx.xx/accounts/api |
|**profileServiceRoot**|URL of account service. http://xxx.xxx.xx.xx/profiles/api |
|**secret**|The path of account service's public key file. This is the path from `server` directory `path/to/pubkey.pem` |


## Static file Server Settings

API Server (server.js) does not provide static files. You'll need to set up a static file server such as nginx or httpd. Once your browser recieved HTML and other assets, the app access to API server. So the reverse proxy setting is also needed.


### Example Settings

**Linux + nginx**

```
location /map/ {
        alias /home/ubuntu/office-maker/server/static/public/;
        try_files $uri.html $uri $uri/ 404.html=404;
}

location /api/ {
        proxy_pass http://localhost:3000/api/;
}
```

**Windows + httpd**

```
# office maker settings
Alias /map C:/WorksMap/workspace/office-maker/server/static/public
<Directory "C:/WorksMap/workspace/office-maker/server/static/public">
    Options Indexes FollowSymLinks MultiViews
    Require all granted
</Directory>
ProxyRequests Off
ProxyPass /api/ http://localhost:3000/api/
ProxyPassReverse /api/ http://localhost:3000/api/
```

## Run server

Currently, this is the same as development.

```
$ node watch
```

## Development

```
$ node watch
```


## License

[Apache License 2.0](LICENSE)
