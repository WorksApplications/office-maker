var url = require('url');
var fs = require('fs-extra');
var _async = require('async');

var sql = require('./sql.js');
var rdb = require('./rdb2.js');
var schema = require('./schema.js');
var filestorage = require('./filestorage.js');
var mock = require('./mock.js');

function saveObjects(conn, data, cb) {
  getObjects(conn, data.floorId, data.oldFloorVersion, function(e, objects) {
    var deleted = {};
    var modified = {};
    data.deleted.forEach((e) => {
      deleted[e.id] = true;
    });
    data.modified.forEach((mod) => {
      mod.new.modifiedVersion = data.newFloorVersion;
      modified[mod.new.id] = mod.new;
    });
    data.added.forEach((mod) => {
      mod.modifiedVersion = data.newFloorVersion;
    });
    var conflict = false;
    objects.forEach(function(e) {
      if((deleted[e.id] || modified[e.id]) && data.baseFloorVersion < e.modifiedVersion) {
        conflict = true;
      }
    });
    if(conflict) {
      cb(409);
    } else {
      var sqls = objects.concat(data.added).filter((e) => {
        return !deleted[e.id];
      }).map((object) => {
        object = modified[object.id] || object
        return sql.replace('objects', schema.objectKeyValues(data.floorId, data.newFloorVersion, object));
      });
      // sqls.unshift(sql.delete('objects', sql.whereList([['floorId', data.floorId], ['floorVersion', data.oldFloorVersion]])));
      rdb.batch(conn, sqls, cb);
    }
  });
}

function getObjects(conn, floorId, floorVersion, cb) {
  var q = sql.select('objects', sql.whereList([['floorId', floorId], ['floorVersion', floorVersion]]));
  rdb.exec(conn, q, cb);
}

function getFloorWithObjects(conn, withPrivate, id, cb) {
  getFloor(conn, withPrivate, id, (e, floor) => {
    if(e) {
      cb(e);
    } else if(!floor) {
      cb(null, null);
    } else {
      getObjects(conn, floor.id, floor.version, (e, objects) => {
        if(e) {
          cb(e);
        } else {
          floor.objects = objects;
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
function getFloorsWithObjects(conn, withPrivate, cb) {
  getFloors(conn, withPrivate, (e, floors) => {
    if(e) {
      cb(e);
    } else {
      var functions = floors.map(function(floor) {
        return function(cb) {
          return getObjects(conn, floor.id, floor.version, cb);
        };
      });
      _async.parallel(functions, function(e, objectsList) {
        if(e) {
          cb(e);
        } else {
          objectsList.forEach(function(objects, i) {
            floors[i].objects = objects;//TODO don't mutate
          });
          cb(null, floors);
        }
      });
    }
  });
}
function getFloorsInfoWithObjects (conn, cb) {
  getFloorsWithObjects(conn, false, (e, floorsNotIncludingLastPrivate) => {
    if(e) {
      cb(e)
    } else {
      getFloorsWithObjects(conn, true, (e, floorsIncludingLastPrivate) => {
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

function saveFloorWithObjects(conn, newFloor, cb) {
  getFloor(conn, true, newFloor.id, (e, floor) => {
    if(e) {
      cb && cb(e);
    } else {
      var baseVersion = newFloor.version;
      newFloor.version = floor ? floor.version + 1 : 0;
      var sqls = [
        sql.insert('floors', schema.floorKeyValues(newFloor))
      ];
      rdb.batch(conn, sqls, (e) => {
        if(e) {
          console.log('saveFloorWithObjects', e);
          cb && cb(e);
        } else {
          saveObjects(conn, {
            floorId: newFloor.id,
            baseFloorVersion: baseVersion,
            oldFloorVersion: floor.version,
            newFloorVersion: newFloor.version,
            added: newFloor.added,
            modified: newFloor.modified,
            deleted: newFloor.deleted
          }, function(e) {
            if(e) {
              cb(e);
            } else {
              cb(null, newFloor.version);
            }
          });
        }
      });
    }
  });
}

function publishFloor(conn, newFloor, cb) {
  saveFloorWithObjects(conn, newFloor, (e, version) => {
    if(e) {
      cb(e);
    } else {
      var sqls = [
        sql.delete('floors', sql.where('id', newFloor.id) + ' and public=0')
      ];
      rdb.batch(conn, sqls, (e) => {
        if(e) {
          cb(e);
        } else {
          cb(null, version);
        }
      });
    }
  });
}

function deleteFloorWithObjects(conn, floorId, cb) {
  var sqls = [
    sql.delete('floors', sql.where('id', floorId)),
    sql.delete('objects', sql.where('floorId', floorId)),
  ];
  rdb.batch(conn, sqls, (e) => {
    if(e) {
      console.log('deleteFloorWithObjects', e);
      cb && cb(e);
    } else {
      cb && cb();
    }
  });
}

function deletePrototype(conn, id, cb) {
  var sqls = [
    sql.delete('prototypes', sql.where('id', id))
  ];
  rdb.batch(conn, sqls, (e) => {
    if(e) {
      console.log('deletePrototype', e);
      cb && cb(e);
    } else {
      cb && cb();
    }
  });
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
      getFloorsWithObjects(conn, all, (e, floors) => {
        if(e) {
          cb(e);
        } else {
          var results = {};
          var arr = [];
          people.forEach((person) => {
            results[person.id] = [];
          });
          floors.forEach((floor) => {
            floor.objects.forEach((e) => {
              if(e.personId) {
                if(results[e.personId]) {
                  results[e.personId].push(e);
                }
              } else if(e.name.toLowerCase().indexOf(query.toLowerCase()) >= 0) {
                // { Nothing, Just } -- objects that has no person
                arr.push({
                  personId : null,
                  objectIdAndFloorId : [e, e.floorId]
                });
              }
            });
          });

          Object.keys(results).forEach((personId) => {
            var objects = results[personId];
            objects.forEach(e => {
              // { Just, Just } -- people who exist in map
              arr.push({
                personId : personId,
                objectIdAndFloorId : [e, e.floorId]
              });
            })
            // { Just, Nothing } -- missing people
            if(!objects.length) {
              arr.push({
                personId : personId,
                objectIdAndFloorId : null
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
      // console.log('init 1');
      saveUser(conn, user, cb);
    };
  }).concat(mock.people.map((person) => {
    return function(cb) {
      // console.log('init 2');
      savePerson(conn, person, cb);
    };
  })).concat([
    function(cb) {
      // console.log('init 3');
      getPrototypes(conn, function(e, prototypes) {
        if(e) {
          cb(e);
        } else {
          if(prototypes.length) {
            cb();
          } else {
            savePrototypes(conn, mock.prototypes, cb);
          }
        }
      });
    }
  ]).concat([
    function(cb) {
      // console.log('init 4');
      saveColors(conn, mock.backgroundColors, cb);
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
        console.log(e);
        done(e);
      } else {
        done(null, function onFinishClose() {});
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
  getFloorWithObjects: getFloorWithObjects,
  // getFloorsWithObjects: getFloorsWithObjects,
  getFloorsInfoWithObjects: getFloorsInfoWithObjects,
  ensureFloor: ensureFloor,
  saveFloorWithObjects: saveFloorWithObjects,
  publishFloor: publishFloor,
  deleteFloorWithObjects: deleteFloorWithObjects,
  deletePrototype: deletePrototype,
  saveImage: saveImage,
  resetImage: resetImage
};
