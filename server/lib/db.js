var url = require('url');

var sql = require('./sql.js');
var rdb = require('./mysql.js');
var schema = require('./schema.js');
var filestorage = require('../static/filestorage.js');
var profileService = require('./profile-service.js');
var searchOptimizer = require('./search-optimizer.js');


function saveObjectsChange(conn, changes) {
  var updateAt = Date.now();
  return changes.reduce((memo, change) => {
    return memo.then(changes => {
      change.object.floorVersion = -1;
      if(change.flag == 'added') {
        return addObject(conn, change.object, updateAt).then(object => {
          change.object = object;
          changes.push(change);
          return Promise.resolve(changes);
        });
      } else if(change.flag == 'modified') {
        return updateObject(conn, change.object, updateAt).then(object => {
          change.object = object;
          changes.push(change);
          return Promise.resolve(changes);
        });
      } else if(change.flag == 'deleted') {
        return deleteObject(conn, change.object).then(object => {
          change.object = object;
          changes.push(change);
          return Promise.resolve(changes);
        });
      } else {
        throw "valid flag is not set";
      }
    });
  }, Promise.resolve([]));
}

function addObject(conn, object, updateAt) {
  var query = sql.insert('objects', schema.objectKeyValues(object, updateAt));
  return rdb.exec(conn, query).then((okPacket) => {
    if(!okPacket.affectedRows) {
      console.log(`didn't update by ` + query);
      return Promise.reject(object);
    } else {
      object.updateAt = updateAt;
      return Promise.resolve(object);
    }
  });
}

function updateObject(conn, object, updateAt) {
  var oldUpdateAt = object.updateAt;
  var query = sql.update('objects', schema.objectKeyValues(object, updateAt),
    sql.whereList([['id', object.id], ['updateAt', oldUpdateAt]]) + ' AND floorVersion = -1'
  );
  return rdb.exec(conn, query).then((okPacket) => {
    if(!okPacket.affectedRows) {
      console.log(`didn't update by ` + query);
      return Promise.reject(object);
    } else {
      object.updateAt = updateAt;
      return Promise.resolve(object);
    }
  });
}

function deleteObject(conn, object) {
  var oldUpdateAt = object.updateAt;
  var query = sql.delete('objects',
    sql.whereList([['id', object.id], ['updateAt', oldUpdateAt]]) + ' AND floorVersion = -1'
  );
  return rdb.exec(conn, query).then((okPacket) => {
    if(!okPacket.affectedRows) {
      console.log(`didn't update by ` + query);
      return Promise.reject(object);
    } else {
      return Promise.resolve(object);
    }
  });
}

function fixBool(obj) {
  if(obj) {
    obj.bold = !!obj.bold;
  }
  return obj;
}

function getObjectByIdFromPublicFloor(conn, objectId) {
  var q = sql.select('objects', sql.whereList([['id', objectId]]) + ' AND floorVersion >= 0 ORDER BY floorVersion DESC LIMIT 1');
  return rdb.one(conn, q).then(obj => fixBool(obj));
}

function getObjects(conn, floorId, floorVersion) {
  var q = sql.select('objects', sql.whereList([['floorId', floorId], ['floorVersion', floorVersion]]));
  return rdb.exec(conn, q).then(objs => objs.map(fixBool));
}

function getPublicFloorWithObjects(conn, tenantId, id) {
  return getFloorWithObjects(conn, getPublicFloor(conn, tenantId, id));
}

function getEditingFloorWithObjects(conn, tenantId, id) {
  return getFloorWithObjects(conn, getEditingFloor(conn, tenantId, id));
}

function getFloorOfVersionWithObjects(conn, tenantId, id, version) {
  return getFloorWithObjects(conn, getFloorOfVersion(conn, tenantId, id, version));
}

function getFloorWithObjects(conn, getFloor) {
  return getFloor.then((floor) => {
    if(!floor) {
      return Promise.resolve(null);
    }
    return getObjects(conn, floor.id, floor.version).then((objects) => {
      floor.objects = objects;
      return Promise.resolve(floor);
    });
  });
}


function getFloorOfVersion(conn, tenantId, id, version) {
  var q = sql.select('floors', sql.whereList([['id', id], ['tenantId', tenantId], ['version', version]]));
  return rdb.one(conn, q);
}

function getPublicFloor(conn, tenantId, id) {
  return rdb.exec(conn,
    sql.select('floors', sql.whereList([['id', id], ['tenantId', tenantId]]) + ' AND version >= 0 ORDER BY version DESC LIMIT 1')
  ).then((floors) => {
    return Promise.resolve(floors[0]);
  });
}

function getEditingFloor(conn, tenantId, id) {
  return rdb.exec(conn,
    sql.select('floors', sql.whereList([['id', id], ['tenantId', tenantId], ['version', -1]]))
  ).then((floors) => {
    return Promise.resolve(floors[0]);
  });
}

function getPublicFloors(conn, tenantId) {
  return rdb.exec(conn,
    sql.select('floors', sql.whereList([['tenantId', tenantId]]) + ' AND version >= 0')
  ).then((floors) => {
    var results = {};
    floors.forEach((floor) => {
      if(!results[floor.id] || results[floor.id].version < floor.version) {
        results[floor.id] = floor;
      }
    });
    var ret = Object.keys(results).map((id) => {
      return results[id];
    });
    return Promise.resolve(ret);
  });
}

function getEditingFloors(conn, tenantId) {
  return rdb.exec(conn,
    sql.select('floors', sql.whereList([['tenantId', tenantId], ['version', -1]]))
  );
}

function getFloorsWithObjects(conn, tenantId, withPrivate) {
  var getFloors = withPrivate ? getEditingFloors(conn, tenantId) : getPublicFloors(conn, tenantId);
  return getFloors.then((floors) => {
    var promises = floors.map((floor) => {
      return getObjects(conn, floor.id, floor.version).then((objects) => {
        floor.objects = objects;
        return Promise.resolve(floor);
      });
    });
    return Promise.all(promises);
  });
}

function getFloorsInfo(conn, tenantId) {
  return getPublicFloors(conn, tenantId).then((publicFloors) => {
    return getEditingFloors(conn, tenantId).then((editingFloors) => {
      var floorInfos = {};
      publicFloors.forEach((floor) => {
        floorInfos[floor.id] = floorInfos[floor.id] || [];
        floorInfos[floor.id][0] = floor;
      });
      editingFloors.forEach((floor) => {
        floorInfos[floor.id] = floorInfos[floor.id] || [];
        floorInfos[floor.id][1] = floor;
      });
      // console.log(floorInfos);
      var values = Object.keys(floorInfos).map((key) => {
        return floorInfos[key];
      });
      // values.forEach((value) => {
      //   value[0] = value[0] || value[1];
      //   value[1] = value[1] || value[0];
      // });
      return Promise.resolve(values);
    });
  });
}

function saveOrCreateFloor(conn, tenantId, newFloor) {
  validateFloor(newFloor);
  var oldUpdateAt = newFloor.updateAt;
  var updateAt = Date.now();
  return getEditingFloor(conn, tenantId, newFloor.id).then((floor) => {
    if(floor) {
      return updateEditingFloor(conn, tenantId, newFloor, updateAt);
    } else {
      return createEditingFloor(conn, tenantId, newFloor, updateAt);
    }
  });
}

function validateFloor(newFloor) {
  if((typeof newFloor.id) !== 'string') {
    throw "invalid!";
  }
  if(newFloor.id.length !== 36) {
    throw "invalid!";
  }
  if((typeof newFloor.name) !== 'string') {
    throw "invalid!";
  }
  if(!newFloor.name.trim()) {
    throw "invalid!";
  }
  if((typeof newFloor.ord) !== 'number') {
    throw "invalid!";
  }
}

function updateEditingFloor(conn, tenantId, newFloor, updateAt) {
  newFloor.version = -1;
  return rdb.exec(
    conn,
    sql.update('floors', schema.floorKeyValues(tenantId, newFloor, updateAt),
      sql.whereList([['id', newFloor.id], ['tenantId', tenantId], ['version', newFloor.version]])
    )
  ).then(() => {
    newFloor.updateAt = updateAt;
    return Promise.resolve(newFloor);
  });
}

function createEditingFloor(conn, tenantId, newFloor, updateAt) {
  newFloor.version = -1;
  return rdb.exec(
    conn,
    sql.insert('floors', schema.floorKeyValues(tenantId, newFloor, updateAt))
  ).then(() => {
    newFloor.updateAt = updateAt;
    return Promise.resolve(newFloor);
  });
}

function saveFloor(conn, tenantId, newFloor, updateBy) {
  var updateAt = Date.now();
  newFloor.version = -1;
  newFloor.updateBy = updateBy;
  newFloor.updateAt = updateAt;
  return saveOrCreateFloor(conn, tenantId, newFloor);
}

function publishFloor(conn, tenantId, floorId, updateBy) {
  return getEditingFloorWithObjects(conn, tenantId, floorId).then((editingFloor) => {
    if(!editingFloor) {
      return Promise.reject('Editing floor not found: ' + floorId);
    }
    return getPublicFloor(conn, tenantId, floorId).then((lastPublicFloor) => {
      var updateAt = Date.now();
      var newFloorVersion = lastPublicFloor ? lastPublicFloor.version + 1 : 0;// better to increment by DB

      var sqls = [];
      editingFloor.updateBy = updateBy;
      editingFloor.version = newFloorVersion;
      sqls.push(sql.insert('floors', schema.floorKeyValues(tenantId, editingFloor, updateAt)));

      editingFloor.objects.forEach((object) => {
        object.floorVersion = newFloorVersion;
        object.updateAt = updateAt;
        sqls.push(sql.insert('objects', schema.objectKeyValues(object, updateAt)));
      });

      return rdb.batch(conn, sqls).then(() => {
        editingFloor.updateAt = updateAt;
        return Promise.resolve(editingFloor);
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

function deleteFloor(conn, tenantId, floorId) {
  var sqls = [
    sql.delete('floors', sql.whereList([['id', floorId], ['tenantId', tenantId]]))
  ];
  return rdb.batch(conn, sqls);
}

function deleteFloorWithObjects(conn, tenantId, floorId) {
  var sqls = [
    sql.delete('floors', sql.whereList([['id', floorId], ['tenantId', tenantId]])),
    sql.delete('objects', sql.whereList([['floorId', floorId]])),
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

function matchToQuery(object, normalizedQuery) {
  var keys = searchOptimizer.getKeys(object);
  for(var i = 0; i < keys.length; i++) {
    if(keys[i].startsWith(normalizedQuery)) {
      return true;
    }
  }
  return false;
}

function search(conn, tenantId, query, all, people) {
  var normalizedQuery = searchOptimizer.normalize(query);
  return getFloorsWithObjects(conn, tenantId, all).then(floors => {
    var results = {};
    var arr = [];
    people.forEach(person => {
      results[person.id] = [];
    });
    floors.forEach(floor => {
      floor.objects.forEach(object => {
        if(object.personId) {
          if(results[object.personId]) {
            results[object.personId].push(object);
          }
        } else if(matchToQuery(object, normalizedQuery)) {
          // { Nothing, Just } -- objects that has no person
          arr.push({
            personId : null,
            objectAndFloorId : [object, object.floorId]
          });
        }
      });
    });

    Object.keys(results).forEach((personId) => {
      var objects = results[personId];
      objects.forEach(object => {
        // { Just, Just } -- people who exist in map
        arr.push({
          personId : personId,
          objectAndFloorId : [object, object.floorId]
        });
      })
      // { Just, Nothing } -- missing people
      if(!objects.length) {
        arr.push({
          personId : personId,
          objectAndFloorId : null
        });
      }
    });
    return Promise.resolve(arr);
  });
}

function getPrototypes(conn, tenantId) {
  return rdb.exec(conn, sql.select('prototypes', sql.where('tenantId', tenantId)));
}

function savePrototype(conn, tenantId, newPrototype) {
  return rdb.exec(conn, sql.replace('prototypes', schema.prototypeKeyValues(tenantId, newPrototype)));
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
  var inserts = colors.map((c, index) => {
    c.id = index + '';
    return schema.colorKeyValues(tenantId, c);
  }).map((keyValues) => {
    return sql.insert('colors', keyValues);
  });
  inserts.unshift(sql.delete('colors', sql.where('tenantId', tenantId)));
  return rdb.batch(conn, inserts);
}

module.exports = {
  search: search,
  getPrototypes: getPrototypes,
  savePrototype: savePrototype,
  savePrototypes: savePrototypes,
  getColors: getColors,
  saveColors: saveColors,
  getEditingFloorWithObjects: getEditingFloorWithObjects,
  getPublicFloorWithObjects: getPublicFloorWithObjects,
  getFloorOfVersionWithObjects: getFloorOfVersionWithObjects,
  getFloorsInfo: getFloorsInfo,
  saveFloor: saveFloor,
  getObjectByIdFromPublicFloor: getObjectByIdFromPublicFloor,
  saveObjectsChange: saveObjectsChange,
  publishFloor: publishFloor,
  deleteFloor: deleteFloor,
  deleteFloorWithObjects: deleteFloorWithObjects,
  deletePrototype: deletePrototype,
  saveImage: saveImage,
  resetImage: resetImage
};
