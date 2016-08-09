var db = require('./db.js');
var rdb = require('./rdb.js');
var mock = require('./mock.js');
var _async = require('async');

var rdbEnv = rdb.createEnv('localhost', 'root', '', 'map2');

var commands = {};

commands.createDataForDebug = function(cb) {
  rdbEnv.forConnectionAndTransaction((e, conn, done) => {
    if(e) {
      cb(e);
    } else {
      createDataForDebug(conn, (e) => {
        if(e) {
          cb(e);
        } else {
          done(false, function(commitFailed) {
            if(commitFailed) {
              console.log(commitFailed);
              cb(commitFailed);
            } else {
              cb();
            }
          });
        }
      });
    }
  });
};

commands.deleteFloor = function(floorId, cb) {
  rdbEnv.forConnectionAndTransaction((e, conn, done) => {
    if(e) {
      cb(e);
    } else {
      console.log('deleting floor ' + floorId + '...');
      db.deleteFloorWithObjects(conn, floorId, (e) => {
        if(e) {
          cb(e);
        } else {
          done(false, function(commitFailed) {
            if(commitFailed) {
              console.log(commitFailed);
              cb(commitFailed);
            } else {
              cb();
            }
          });
        }
      });
    }
  });
};

commands.deletePrototype = function(id, cb) {
  rdbEnv.forConnectionAndTransaction((e, conn, done) => {
    if(e) {
      cb(e);
    } else {
      console.log('deleting prototype ' + id + '...');
      db.deletePrototype(conn, id, (e) => {
        if(e) {
          cb(e);
        } else {
          done(false, function(commitFailed) {
            if(commitFailed) {
              console.log(commitFailed);
              cb(commitFailed);
            } else {
              cb();
            }
          });
        }
      });
    }
  });
};

commands.resetImage = function(cb) {
  db.resetImage(null, 'images/floors', cb);
};


function createDataForDebug(conn, cb) {
  _async.series(mock.users.map((user) => {
    return function(cb) {
      db.saveUser(conn, user, cb);
    };
  }).concat(mock.people.map((person) => {
    return function(cb) {
      db.savePerson(conn, person, cb);
    };
  })).concat([
    function(cb) {
      db.getPrototypes(conn, function(e, prototypes) {
        if(e) {
          cb(e);
        } else {
          if(prototypes.length) {
            cb();
          } else {
            db.savePrototypes(conn, mock.prototypes, cb);
          }
        }
      });
    }
  ]).concat([
    function(cb) {
      var colors = mock.backgroundColors.map(function(c, index) {
        var id = index + '';
        var ord = index;
        return {
          id: id,
          ord: ord,
          type: 'backgroundColor',
          color: c
        };
      }).concat(mock.colors.map(function(c, index) {
        var id = (mock.backgroundColors.length + index) + '';
        var ord = (mock.backgroundColors.length + index);
        return {
          id: id,
          ord: ord,
          type: 'color',
          color: c
        };
      }));
      db.saveColors(conn, colors, cb);
    }
  ]), cb);
}

//------------------

var args = process.argv;
args.shift();// node
args.shift();// test/server/commands.js
var funcName = args.shift();

commands[funcName].apply(null, [...args, (e) => {
  if(e) {
    console.log(e);
  } else {
    console.log('done');
  }
}]);
