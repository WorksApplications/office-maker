var db = require('./db.js');
var rdb = require('./rdb2.js');

var commands = {};

commands.deleteFloor = function(floorId, cb) {
  rdb.forConnectionAndTransaction((e, conn, done) => {
    if(e) {
      console.log(e)
      cb(e);
    } else {
      console.log('deleting ' + floorId + '...');
      db.deleteFloorWithEquipments(conn, floorId, (e) => {
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
