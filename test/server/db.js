var url = require('url');
var fs = require('fs-extra');
var _async = require('async');

var sql = require('./sql.js');
var rdb = require('./rdb2.js');
var schema = require('./schema.js');
var filestorage = require('./filestorage.js');
var mock = require('./mock.js');

function saveEquipments(conn, floorId, floorVersion, equipments, cb) {
  var sqls = equipments.map((equipment) => {
    return sql.replace('equipments', schema.equipmentKeyValues(floorId, floorVersion, equipment));
  });
  sqls.unshift(sql.delete('equipments', sql.whereList([['floorId', floorId], ['floorVersion', floorVersion]])));
  rdb.batch(conn, sqls, cb);
}
function getEquipments(conn, floorId, floorVersion, cb) {
  var q = sql.select('equipments', sql.whereList([['floorId', floorId], ['floorVersion', floorVersion]]));
  rdb.exec(conn, q, cb);
}
function getFloorWithEquipments(conn, withPrivate, id, cb) {
  getFloor(conn, withPrivate, id, (e, floor) => {
    if(e) {
      cb(e);
    } else if(!floor) {
      cb(null, null);
    } else {
      getEquipments(conn, floor.id, floor.version, (e, equipments) => {
        if(e) {
          cb(e);
        } else {
          floor.equipments = equipments;
          cb(null, floor);
        }
      });
    }
  });
}
function getFloor(conn, withPrivate, id, cb) {
  var q = sql.select('floors', sql.where('id', id))

  rdb.exec(conn, q, (e, floors) => {
    if(e) {
      cb(e);
    } else {
      var _floor = null;
      floors.forEach((floor) => {
        if(!_floor || _floor.version < floor.version) {
          if(floor.public || withPrivate) {
            _floor = floor;
          }
        }
      });
      cb(null, _floor);
    }
  });
}
function getFloors(conn, withPrivate, cb) {
  rdb.exec(conn, sql.select('floors'), (e, floors) => {
    if(e) {
      cb(e);
    } else {
      var results = {};
      floors.forEach((floor) => {
        if(!results[floor.id] || results[floor.id].version < floor.version) {
          if(floor.public || withPrivate) {
            results[floor.id] = floor;
          }
        }
      });
      var ret = Object.keys(results).map((id) => {
        return results[id];
      });
      cb(null, ret);
    }
  });
}
function getFloorsWithEquipments(conn, withPrivate, cb) {
  getFloors(conn, withPrivate, (e, floors) => {
    if(e) {
      cb(e);
    } else {
      var functions = floors.map(function(floor) {
        return function(cb) {
          return getEquipments(conn, floor.id, floor.version, cb);
        };
      });
      _async.parallel(functions, function(e, equipmentsList) {
        if(e) {
          cb(e);
        } else {
          equipmentsList.forEach(function(equipments, i) {
            floors[i].equipments = equipments;//TODO don't mutate
          });
          cb(null, floors);
        }
      });
    }
  });
}
function getFloorsInfoWithEquipments (conn, cb) {
  getFloorsWithEquipments(conn, false, (e, floorsNotIncludingLastPrivate) => {
    if(e) {
      cb(e)
    } else {
      getFloorsWithEquipments(conn, true, (e, floorsIncludingLastPrivate) => {
        if(e) {
          cb(e)
        } else {
          var floorInfos = {};
          floorsNotIncludingLastPrivate.forEach(function(floor) {
            floorInfos[floor.id] = floorInfos[floor.id] || [];
            floorInfos[floor.id][0] = floor;
          });
          floorsIncludingLastPrivate.forEach(function(floor) {
            floorInfos[floor.id] = floorInfos[floor.id] || [];
            floorInfos[floor.id][1] = floor;
          });
        }
        var values = Object.keys(floorInfos).map(function(key) {
          return floorInfos[key];
        });
        values.forEach(function(value) {
          value[0] = value[0] || value[1];
          value[1] = value[1] || value[0];
        });
        cb(null, values);
      });
    }

  });
}
function ensureFloor(conn, id, cb) {
  cb && cb();
}
function saveFloorWithEquipments(conn, newFloor, incrementVersion, cb) {
  if(!newFloor.equipments) {
    throw "invalid: ";
  }
  console.log('newFloor.equipments.length', newFloor.equipments.length);
  getFloor(conn, true, newFloor.id, (e, floor) => {
    if(e) {
      cb && cb(e);
    } else {
      newFloor.version = floor ? (incrementVersion ? floor.version + 1 : floor.version) : 0;
      var sqls = [
        sql.delete('floors', sql.where('id', newFloor.id) + ' and public=0'),
        sql.insert('floors', schema.floorKeyValues(newFloor))
      ];
      rdb.batch(conn, sqls, (e) => {
        if(e) {
          console.log('saveFloorWithEquipments', e);
          cb && cb(e);
        } else {
          saveEquipments(conn, newFloor.id, newFloor.version, newFloor.equipments, cb);
        }
      });
    }
  });
}

function publishFloor(conn, newFloor, cb) {
  saveFloorWithEquipments(conn, newFloor, true, cb);
}

function saveUser(conn, user, cb) {
  if(!conn) {
    console.log('connection does not exist');
    console.trace();
    throw 'connection does not exist';
  }
  rdb.batch(conn, [
    // sql.delete('users', sql.where('id', user.id)),
    sql.replace('users', schema.userKeyValues(user))
  ], cb);
}

function savePerson(conn, person, cb) {
  rdb.batch(conn, [
    // sql.delete('people', sql.where('id', person.id)),
    sql.replace('people', schema.personKeyValues(person))
  ], cb);
}

function saveImage(conn, path, image, cb) {
  filestorage.save(path, image, cb);
}
function resetImage(conn, dir, cb) {
  filestorage.empty(dir, cb);
}
function getPeopleLikeName(conn, name, cb) {
  rdb.exec(conn, sql.select('people', `WHERE name LIKE '%${name.trim()}%' OR mail LIKE '%${name.trim()}%'`), cb);//TODO sanitize
}
function getCandidate(conn, name, cb) {
  getPeopleLikeName(conn, name, cb);
}
function search(conn, query, all, cb) {
  getPeopleLikeName(conn, query, (e, people) => {
    if(e) {
      cb(e);
    } else {
      getFloorsWithEquipments(conn, all, (e, floors) => {
        if(e) {
          cb(e);
        } else {
          var results = {};
          var arr = [];
          people.forEach((person) => {
            results[person.id] = [];
          });
          floors.forEach((floor) => {
            floor.equipments.forEach((e) => {
              if(e.name.toLowerCase().indexOf(query.toLowerCase()) >= 0) {
                if(e.personId) {
                  if(!results[e.personId]) {
                    results[e.personId] = [];
                  }
                  results[e.personId].push(e);
                } else {
                  // { Nothing, Just } -- equipments that has no person
                  arr.push({
                    personId : null,
                    equipmentIdAndFloorId : [e, e.floorId]
                  });
                }

              }
            });
          });

          Object.keys(results).forEach((personId) => {
            var equipments = results[personId];
            equipments.forEach(e => {
              // { Just, Just } -- people who exist in map
              arr.push({
                personId : personId,
                equipmentIdAndFloorId : [e, e.floorId]
              });
            })
            // { Just, Nothing } -- missing people
            if(!equipments.length) {
              arr.push({
                personId : personId,
                equipmentIdAndFloorId : null
              });
            }
          });
          cb(null, arr);
        }
      });
    }
  });

}
function getPrototypes(conn, cb) {
  rdb.exec(conn, sql.select('prototypes'), (e, prototypes) => {
    cb(null, prototypes);
  });
}
function savePrototypes(conn, newPrototypes, cb) {
  var inserts = newPrototypes.map((proto) => {
    return sql.insert('prototypes', schema.prototypeKeyValues(proto));
  });
  inserts.unshift(sql.delete('prototypes'));
  rdb.batch(conn, inserts, cb);
}
function getUser(conn, id, cb) {
  rdb.exec(conn, sql.select('users', sql.where('id', id)), (e, users) => {
    if(e) {
      cb(e);
    } else if(users.length < 1) {
      cb(null, null);
    } else {
      cb(null, users[0]);
    }
  });
}
function getUserWithPerson(conn, id, cb) {
  getUser(conn, id, (e, user) => {
    if(e) {
      cb(e);
    } else if(!user) {
      cb(null, null);
    } else {
      getPerson(conn, user.personId, (e, person) => {
        if(e) {
          cb(e);
        } else {
          cb(null, Object.assign({}, user, { person: person }));
        }
      });
    }
  });
}
function getPerson(conn, id, cb) {
  rdb.exec(conn, sql.select('people', sql.where('id', id)), (e, people) => {
    if(e) {
      cb(e);
    } else if(people.length < 1) {
      cb(null, null);
    } else {
      cb(null, people[0]);
    }
  });
}
function getColors(conn, cb) {
  rdb.exec(conn, sql.select('colors', sql.where('id', '1')), (e, colors) => {
    if(e) {
      cb(e);
    } else {
      var _colors = [];
      [1,2,3,4,5,6,7,8,9,10].forEach((i) => {
        var c = colors[0]['color' + i];
        if(c) {
          _colors.push(c);
        }
      });
      cb(null, _colors);
    }
  });
}
function saveColors(conn, newColors, cb) {
  var keyValues = newColors.map((c, index) => {
    return ['color' + index, c];
  });
  keyValues.unshift(['id', '1']);
  rdb.batch(conn, [
    // sql.delete('colors'),
    sql.replace('colors', keyValues)
  ], cb);
}

function init(conn, cb) {

  _async.series(mock.users.map((user) => {
    return function(cb) {
      saveUser(conn, user, cb);
    };
  }).concat(mock.people.map((person) => {
    return function(cb) {
      savePerson(conn, person, cb);
    };
  })).concat([
    function(cb) {
      savePrototypes(conn, mock.prototypes, cb);
    }
  ]).concat([
    function(cb) {
      saveColors.bind(conn, mock.colors, cb)
    }
  ]), cb);
}
rdb.forConnectionAndTransaction((e, conn, done) => {
  if(e) {
    done(e);
  } else {
    init(conn, (e) => {
      // console.log('init done?', e);
      if(e) {
        done(true);
      } else {
        done();
      }
    });
  }
});


module.exports = {
  getUser: getUser,
  getUserWithPerson: getUserWithPerson,
  getPerson: getPerson,
  getCandidate: getCandidate,
  search: search,
  getPrototypes: getPrototypes,
  savePrototypes: savePrototypes,
  getColors: getColors,
  saveColors: saveColors,
  getFloorWithEquipments: getFloorWithEquipments,
  // getFloorsWithEquipments: getFloorsWithEquipments,
  getFloorsInfoWithEquipments: getFloorsInfoWithEquipments,
  ensureFloor: ensureFloor,
  saveFloorWithEquipments: saveFloorWithEquipments,
  publishFloor: publishFloor,
  saveImage: saveImage,
  resetImage: resetImage
};
