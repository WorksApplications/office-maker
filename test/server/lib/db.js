var url = require('url');
var fs = require('fs-extra');
var _async = require('async');

var sql = require('./sql.js');
var rdb = require('./mysql.js');
var schema = require('./schema.js');
var filestorage = require('./filestorage.js');
var profileService = require('./profile-service.js');


function getUser(conn, id) {
  return rdb.exec(conn, sql.select('users', sql.where('id', id))).then((users) => {
    if(users[0]) {
      users[0].pass = '';
      users[0].tenantId = '';
    }
    return Promise.resolve(users[0]);
  });
}

function saveUser(conn, user) {
  return rdb.batch(conn, [
    // sql.delete('users', sql.where('id', user.id)),
    sql.replace('users', schema.userKeyValues(user))
  ]);
}

function getPerson(conn, id) {
  return rdb.exec(conn, sql.select('people', sql.where('id', id))).then((people) => {
    return Promise.resolve(people[0]);
  });
}

function savePerson(conn, person) {
  return rdb.batch(conn, [
    // sql.delete('people', sql.where('id', person.id)),
    sql.replace('people', schema.personKeyValues(person))
  ]);
}

function getPeopleLikeName(conn, name) {
  return rdb.exec(conn, sql.select('people', `WHERE name LIKE '%${name.trim()}%' OR mail LIKE '%${name.trim()}%'`));//TODO sanitize
}

function getCandidate(conn, name) {
  return getPeopleLikeName(conn, name);
}

//-------------------

function saveObjects(conn, data) {
  return getObjects(conn, data.floorId, data.oldFloorVersion).then((objects) => {
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
    objects.forEach((e) => {
      if((deleted[e.id] || modified[e.id]) && data.baseFloorVersion < e.modifiedVersion) {
        conflict = true;
      }
    });
    if(conflict) {
      return Promise.reject(409);
    }
    var sqls = objects.concat(data.added).filter((e) => {
      return !deleted[e.id];
    }).map((object) => {
      object = modified[object.id] || object;
      return sql.insert('objects', schema.objectKeyValues(data.floorId, data.newFloorVersion, object));
    });
    return rdb.batch(conn, sqls);
  });
}

function getObjects(conn, floorId, floorVersion) {
  var q = sql.select('objects', sql.whereList([['floorId', floorId], ['floorVersion', floorVersion]]));
  return rdb.exec(conn, q);
}

function getFloorWithObjects(conn, tenantId, withPrivate, id) {
  return getFloor(conn, tenantId, withPrivate, id).then((floor) => {
    if(!floor) {
      return Promise.resolve(null);
    }
    return getObjects(conn, floor.id, floor.version).then((objects) => {
      floor.objects = objects;
      return Promise.resolve(floor);
    });
  });
}

function getFloor(conn, tenantId, withPrivate, id) {
  var q = sql.select('floors', sql.whereList([['id', id], ['tenantId', tenantId]]));
  return rdb.exec(conn, q).then((floors) => {
    var _floor = null;
    floors.forEach((floor) => {
      if(!_floor || _floor.version < floor.version) {
        if(floor.public || withPrivate) {
          _floor = floor;
        }
      }
    });
    return Promise.resolve(_floor);
  });
}

function getFloors(conn, tenantId, withPrivate) {
  var sql_ = sql.select('floors', sql.where('tenantId', tenantId));
  return rdb.exec(conn, sql_).then((floors) => {
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
    return Promise.resolve(ret);
  });
}

function getFloorsWithObjects(conn, tenantId, withPrivate) {
  return getFloors(conn, tenantId, withPrivate).then((floors) => {
    var promises = floors.map((floor) => {
      return getObjects(conn, floor.id, floor.version).then((objects) => {
        floor.objects = objects;
        return Promise.resolve(floor);
      });
    });
    return Promise.all(promises);
  });
}

function getFloorsInfoWithObjects(conn, tenantId) {
  return getFloorsWithObjects(conn, tenantId, false).then((floorsNotIncludingLastPrivate) => {
    return getFloorsWithObjects(conn, tenantId, true).then((floorsIncludingLastPrivate) => {
      var floorInfos = {};
      floorsNotIncludingLastPrivate.forEach((floor) => {
        floorInfos[floor.id] = floorInfos[floor.id] || [];
        floorInfos[floor.id][0] = floor;
      });
      floorsIncludingLastPrivate.forEach((floor) => {
        floorInfos[floor.id] = floorInfos[floor.id] || [];
        floorInfos[floor.id][1] = floor;
      });
      var values = Object.keys(floorInfos).map((key) => {
        return floorInfos[key];
      });
      values.forEach((value) => {
        value[0] = value[0] || value[1];
        value[1] = value[1] || value[0];
      });
      return Promise.resolve(values);
    });
  });
}

function saveFloorWithObjects(conn, tenantId, newFloor, updateBy) {
  newFloor.public = false;
  newFloor.updateBy = updateBy;
  newFloor.updateAt = new Date().getTime();
  return getFloor(conn, tenantId, true, newFloor.id).then((floor) => {
    var baseVersion = newFloor.version;//TODO
    var oldFloorVersion = floor ? floor.version : -1;
    newFloor.version = oldFloorVersion + 1;
    var sqls = [
      sql.insert('floors', schema.floorKeyValues(tenantId, newFloor))
    ];
    return rdb.batch(conn, sqls).then(() => {
      return saveObjects(conn, {
        floorId: newFloor.id,
        baseFloorVersion: baseVersion,
        oldFloorVersion: oldFloorVersion,
        newFloorVersion: newFloor.version,
        added: newFloor.added,
        modified: newFloor.modified,
        deleted: newFloor.deleted
      }).then(() => {
        return Promise.resolve({ id: newFloor.id, version: newFloor.version });
      });
    });
  });
}

function publishFloor(conn, tenantId, floorId, updateBy) {
  return getFloor(conn, tenantId, true, floorId).then((floor) => {
    if(!floor) {
      return Promise.reject('floor not found: ' + floorId);
    }
    var baseVersion = floor.version;
    var oldFloorVersion = floor.version;
    floor.version = floor.version + 1;
    floor.public = true;
    floor.updateBy = updateBy;
    floor.updateAt = new Date().getTime();
    var sqls = [
      sql.replace('floors', schema.floorKeyValues(tenantId, floor)),
      sql.delete('floors', sql.whereList([['id', floor.id], ['tenantId', tenantId]]) + ' and public=0')
    ];
    return rdb.batch(conn, sqls).then(() => {
      return saveObjects(conn, {
        floorId: floorId,
        baseFloorVersion: baseVersion,
        oldFloorVersion: oldFloorVersion,
        newFloorVersion: floor.version,
        added: [],
        modified: [],
        deleted: []
      }).then(() => {
        return deleteUnrelatedObjects(conn).then(() => {
          return Promise.resolve(floor.version);
        });
      });
    });
  });
}

function deleteUnrelatedObjects(conn) {
  return rdb.exec(conn,
  `DELETE FROM objects
      WHERE
          NOT EXISTS( SELECT
              1
          FROM
              floors AS f
          WHERE
              objects.floorId = f.id
              AND objects.floorVersion = f.version)`
  );
}

function deleteFloorWithObjects(conn, tenantId, floorId) {
  var sqls = [
    sql.delete('floors', sql.whereList([['id', floorId], ['tenantId', tenantId]])),
    sql.delete('objects', sql.whereList([['floorId', floorId], ['tenantId', tenantId]])),
  ];
  return rdb.batch(conn, sqls);
}

function deletePrototype(conn, tenantId, id) {
  var sqls = [
    sql.delete('prototypes', sql.whereList([['id', id], ['tenantId', tenantId]]))
  ];
  return rdb.batch(conn, sqls);
}

function saveImage(conn, path, image) {
  return filestorage.save(path, image);
}

function resetImage(conn, dir) {
  return filestorage.empty(dir);
}

function search(conn, tenantId, query, all) {
  return getPeopleLikeName(conn, query).then((people) => {
    return searchHelp(conn, tenantId, query, all, people);
  });
}

function searchWithProfileService(profileServiceRoot, sessionId, tenantId, query, all) {
  return profielService.search(profileServiceRoot, sessionId, query).then((people) => {
    return searchHelp(conn, tenantId, query, all, people);
  });
}

function searchHelp(conn, tenantId, query, all, people) {
  return searchPeople.then((people) => {
    return getFloorsWithObjects(conn, tenantId, all).then((floors) => {
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
      return Promise.resolve(arr);
    });
  });
}

function getPrototypes(conn, tenantId) {
  return rdb.exec(conn, sql.select('prototypes', sql.where('tenantId', tenantId)));
}

function savePrototypes(conn, tenantId, newPrototypes) {
  var inserts = newPrototypes.map((proto) => {
    return sql.insert('prototypes', schema.prototypeKeyValues(tenantId, proto));
  });
  inserts.unshift(sql.delete('prototypes', sql.where('tenantId', tenantId)));
  return rdb.batch(conn, inserts);
}

function getColors(conn, tenantId) {
  return rdb.exec(conn, sql.select('colors', sql.where('tenantId', tenantId)));
}

function saveColors(conn, tenantId, colors) {
  var inserts = colors.map((c) => {
    return schema.colorKeyValues(tenantId, c);
  }).map((keyValues) => {
    return sql.insert('colors', keyValues);
  });
  inserts.unshift(sql.delete('colors', sql.where('tenantId', tenantId)));
  return rdb.batch(conn, inserts);
}

module.exports = {
  getUser: getUser,
  saveUser: saveUser,
  getPerson: getPerson,
  savePerson: savePerson,
  getCandidate: getCandidate,
  search: search,
  searchWithProfileService: searchWithProfileService,
  getPrototypes: getPrototypes,
  savePrototypes: savePrototypes,
  getColors: getColors,
  saveColors: saveColors,
  getFloorWithObjects: getFloorWithObjects,
  getFloorsInfoWithObjects: getFloorsInfoWithObjects,
  saveFloorWithObjects: saveFloorWithObjects,
  publishFloor: publishFloor,
  deleteFloorWithObjects: deleteFloorWithObjects,
  deletePrototype: deletePrototype,
  saveImage: saveImage,
  resetImage: resetImage
};
