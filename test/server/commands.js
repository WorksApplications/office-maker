var db = require('./db.js');
var rdb = require('./rdb.js');
var mock = require('./mock.js');
var _async = require('async');

var rdbEnv = rdb.createEnv('localhost', 'root', '', 'map2');

var commands = {};

commands.createDataForDebug = function(cb) {
  return new Promise((resolve, reject) => {
    rdbEnv.forConnectionAndTransaction((e, conn, done) => {
      if(e) {
        cb(e);
      } else {
        createDataForDebug(conn).then(() => {
          done(false, function(commitFailed) {
            if(commitFailed) {
              console.log(commitFailed);
              reject(commitFailed);
            } else {
              resolve();
            }
          });
        }).catch(reject);
      }
    });
  });
};

commands.deleteFloor = function(floorId, cb) {
  return new Promise((resolve, reject) => {
    rdbEnv.forConnectionAndTransaction((e, conn, done) => {
      db.deleteFloorWithObjects(conn, floorId).then(() => {
        done(false, function(commitFailed) {
          if(commitFailed) {
            console.log(commitFailed);
            reject(commitFailed);
          } else {
            resolve();
          }
        });
      }).catch(reject);
    });
  });

};

commands.deletePrototype = function(id) {
  return new Promise((resolve, reject) => {
    rdbEnv.forConnectionAndTransaction((e, conn, done) => {
      if(e) {
        reject(e);
      } else {
        console.log('deleting prototype ' + id + '...');
        db.deletePrototype(conn, id).then(() => {
          done(false, function(commitFailed) {
            if(commitFailed) {
              console.log(commitFailed);
              reject(commitFailed);
            } else {
              resolve();
            }
          });
        }).catch(reject);
      }
    });
  });

};

commands.resetImage = function() {
  return db.resetImage(null, 'images/floors');
};

function createDataForDebug(conn) {
  return Promise.all(mock.users.map((user) => {
    return db.saveUser(conn, user);
  }).concat(mock.people.map((person) => {
    return db.savePerson(conn, person);
  })).concat([
    db.getPrototypes(conn).then((prototypes) => {
      if(prototypes.length) {
        return Promise.resolve();
      } else {
        return db.savePrototypes(conn, mock.prototypes);
      }
    })
  ]).concat([
    db.saveColors(conn, mock.colors)
  ]));
}

//------------------

var args = process.argv;
args.shift();// node
args.shift();// test/server/commands.js
var funcName = args.shift();

commands[funcName].apply(null, [...args]).then(() => {
  console.log('done');
}).catch((e) => {
  console.log(e);
});
