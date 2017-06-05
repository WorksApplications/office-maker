var db = require('./lib/db.js');
var rdb = require('./lib/mysql.js');
var mock = require('./lib/mock.js');
var config = require('./lib/config.js');
var accountService = require('./lib/account-service.js');

var rdbEnv = rdb.createEnv(config.mysql.host, config.mysql.user, config.mysql.pass, 'map2');

function login() {
  return accountService.login(config.accountServiceRoot, config.operationUser, config.operationPass);
}


var commands = {};

commands.createObjectOptTable = function() {
  return login().then(token => {
    return rdbEnv.forConnectionAndTransaction(conn => {
      console.log(`creating optimized object table ...`);
      return db.createObjectOptTable(conn, config.profileServiceRoot, token, true).then(_ => {
        return db.createObjectOptTable(conn, config.profileServiceRoot, token, false);
      });
    });
  });
}

commands.createInitialData = function(tenantId) {
  tenantId = tenantId || '';
  if (config.multiTenency && !tenantId) {
    return Promise.reject('tenantId is not defined.');
  }
  return rdbEnv.forConnectionAndTransaction(conn => {
    console.log(`creating data for tenant ${tenantId} ...`);
    return db.savePrototypes(conn, tenantId, mock.prototypes).then(() => {
      return db.saveColors(conn, tenantId, mock.colors);
    });
  }).then(rdbEnv.end);
};

commands.deleteFloor = function(floorId) {
  if (!floorId) {
    return Promise.reject('floorId is not defined.');
  }
  var tenantId = '';
  return rdbEnv.forConnectionAndTransaction(conn => {
    console.log('deleting floor ' + floorId + '...');
    return db.deleteFloorWithObjects(conn, tenantId, floorId);
  }).then(rdbEnv.end);
};

commands.deletePrototype = function(id) {
  if (!id) {
    return Promise.reject('id is not defined.');
  }
  var tenantId = '';
  return rdbEnv.forConnectionAndTransaction(conn => {
    console.log('deleting prototype ' + id + '...');
    return db.deletePrototype(conn, tenantId, id);
  }).then(rdbEnv.end);
};

commands.resetImage = function() {
  console.log('reseting image ...');
  return db.resetImage(null, 'images/floors');
};

//------------------
// usage:
//
//   node server/commands.js funcName
//
//

var args = process.argv;
args.shift(); // node
args.shift(); // server/commands.js
var funcName = args.shift();
if (funcName) {
  try {
    commands[funcName].apply(null, args).then(() => {
      console.log('done');
      process.exit(0);
    }).catch((e) => {
      console.log(e);
      console.log(e.stack);
      process.exit(1);
    });
  } catch (e) {
    console.log(e);
    console.log(e.stack);
    process.exit(1);
  }
}

module.exports = commands;
