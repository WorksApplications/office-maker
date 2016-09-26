var db = require('./lib/db.js');
var rdb = require('./lib/mysql.js');
var mock = require('./lib/mock.js');
var fs = require('fs');

var config = null;
if(fs.existsSync(__dirname + '/config.json')) {
  config = JSON.parse(fs.readFileSync(__dirname + '/config.json'));
} else {
  config = JSON.parse(fs.readFileSync(__dirname + '/defaultConfig.json'));
}
config.apiRoot = '/api';

var rdbEnv = rdb.createEnv(config.mysql.host, config.mysql.user, config.mysql.pass, 'map2');

var commands = {};

commands.createInitialData = function(tenantId) {
  tenantId = tenantId || '';
  if(config.multiTenency && !tenantId) {
    return Promise.reject('tenantId is not defined.');
  }
  return rdbEnv.forConnectionAndTransaction((conn) => {
    console.log(`creating data for tenant ${tenantId} ...`);
    return db.savePrototypes(conn, tenantId, mock.prototypes).then(() => {
      return db.saveColors(conn, tenantId, mock.colors);
    });
  }).then(rdbEnv.end);
};

commands.deleteFloor = function(floorId) {
  if(!floorId) {
    return Promise.reject('floorId is not defined.');
  }
  var tenantId = '';
  return rdbEnv.forConnectionAndTransaction((conn) => {
    console.log('deleting floor ' + floorId + '...');
    return db.deleteFloorWithObjects(conn, tenantId, floorId);
  }).then(rdbEnv.end);
};

commands.deletePrototype = function(id) {
  if(!id) {
    return Promise.reject('id is not defined.');
  }
  var tenantId = '';
  return rdbEnv.forConnectionAndTransaction((conn) => {
    console.log('deleting prototype ' + id + '...');
    return db.deletePrototype(conn, tenantId, id);
  }).then(rdbEnv.end);
};

commands.resetImage = function() {
  console.log('reseting image ...');
  return db.resetImage(null, 'images/floors');
};

//------------------

var args = process.argv;
args.shift();// node
args.shift();// server/commands.js
var funcName = args.shift();

try {
  commands[funcName].apply(null, args).then(() => {
    console.log('done');
  }).catch((e) => {
    console.log(e);
    console.log(e.stack);
  });
} catch (e) {
  console.log(e);
  console.log(e.stack);
}
