Office Maker Simple Server
----

## Requirement

You need to have MySQL and [Node.js](https://nodejs.org/) (>= 4.0) installed.


## Setup

### Install

Currently, installation is done by [client](../README.md) for ease.

<!--
```
npm install
```
-->

### Initialize

If this is the first time to set up, execute following, which creates config.json and initialize DB.

```
sh initialize.sh
```

There are also other commands in commands.js.

```
node commands.js [commandName] [args]
```

## Configuration

Edit `config.json`. Bold properties are essential to work with various environment.

|name||
|:--|:--|
|mysql.host||
|mysql.user||
|mysql.pass||
|title|This name is used by header.|
|**accountServiceRoot**|URL of account service. http://xxx.xxx.xx.xx/accounts/api |
|**profileServiceRoot**|URL of account service. http://xxx.xxx.xx.xx/profiles/api |
|**secret**|The path of account service's public key file. path/to/pubkey.pem |

## Start Server

Currently, server operations are handled by [client](../README.md) for ease.


## REST API

API is defined by client. See [here](../README.md).


### Table Definition

See [here](./sql/2-create-tables.sql).


## License

[Apache License 2.0](LICENSE)
