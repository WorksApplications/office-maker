var url = require('url');
var fs = require('fs-extra');

var sql = require('./sql.js');
var rdb = require('./mysql.js');
var schema = require('./schema.js');
var filestorage = require('./filestorage.js');
var profileService = require('./profile-service.js');


function saveObjects(conn, added, modified, deleted, updateAt) {
  return added.reduce((memo, object) => {
    return memo.then(objects => {
      return addObject(conn, object, updateAt).then(object => {
        objects.push(object);
        return Promise.resolve(objects);
      });
    });
  }, Promise.resolve([])).then(objects => {
    return modified.reduce((memo, object) => {
      return memo.then(objects => {
        return updateObject(conn, object, updateAt).then(object => {
          objects.push(object);
          return Promise.resolve(objects);
        });
      });
    }, Promise.resolve(objects));
  }).then(objects => {
    return deleted.reduce((memo, object) => {
      return deleteObject(conn, object).then(() => {
        return Promise.resolve(objects);
      });
    }, Promise.resolve(objects));
  });
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
    sql.whereList([['id', object.id]/* TODO recover, ['updateAt', oldUpdateAt]*/]) + ' AND floorVersion = -1'
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
    sql.whereList([['id', object.id]/* TODO recover, ['updateAt', object.updateAt]*/]) + ' AND floorVersion = -1'
  );
  return rdb.exec(conn, query).then((okPacket) => {
    if(!okPacket.affectedRows) {
      console.log(`didn't update by ` + query);
      return Promise.reject(object);
    } else {
      return Promise.resolve();
    }
  });
}

function getObjects(conn, floorId, floorVersion) {
  var q = sql.select('objects', sql.whereList([['floorId', floorId], ['floorVersion', floorVersion]]));
  return rdb.exec(conn, q);
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
    sql.select('floors', sql.whereList([['id', id], ['tenantId', tenantId], ['public', 1]]) + ' ORDER BY version DESC LIMIT 1')
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
    sql.select('floors', sql.whereList([['tenantId', tenantId], ['public', 1]]))
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
  return getEditingFloors(conn, tenantId).then((floorsNotIncludingLastPrivate) => {
    return getPublicFloors(conn, tenantId).then((floorsIncludingLastPrivate) => {
      var floorInfos = {};
      floorsNotIncludingLastPrivate.forEach((floor) => {
        floorInfos[floor.id] = floorInfos[floor.id] || [];
        floorInfos[floor.id][0] = floor;
      });
      floorsIncludingLastPrivate.forEach((floor) => {
        floorInfos[floor.id] = floorInfos[floor.id] || [];
        floorInfos[floor.id][1] = floor;
      });
      // console.log(floorInfos);
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

function saveOrCreateFloor(conn, tenantId, newFloor) {
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

function updateEditingFloor(conn, tenantId, newFloor, updateAt) {
  newFloor.version = -1;
  newFloor.public = false;
  return rdb.exec(
    conn,
    sql.update('floors', schema.floorKeyValues(tenantId, newFloor, updateAt),
      sql.whereList([['id', newFloor.id], ['tenantId', tenantId], ['version', floor.version]])
    )
  ).then(() => {
    newFloor.updateAt = updateAt;
    return Promise.resolve(newFloor);
  });
}

function createEditingFloor(conn, tenantId, newFloor, updateAt) {
  newFloor.version = -1;
  newFloor.public = false;
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
  newFloor.public = false;
  newFloor.updateBy = updateBy;
  newFloor.updateAt = updateAt;
  return saveOrCreateFloor(conn, tenantId, newFloor);
}

function saveObjectsChange(conn, objectsChange) {
  var updateAt = Date.now();
  var added = objectsChange.added.map((object) => {
    object.floorVersion = -1;
    return object;
  });
  var modified = objectsChange.modified.map((object) => {
    object.floorVersion = -1;
    return object;
  });
  var deleted = objectsChange.deleted.map((object) => {
    object.floorVersion = -1;
    return object;
  });
  return saveObjects(conn, added, modified, deleted, updateAt);
}


function publishFloor(conn, tenantId, floorId, updateBy) {
  return getEditingFloorWithObjects(conn, tenantId, floorId).then((editingFloor) => {
    if(!editingFloor) {
      return Promise.reject('Editing floor not found: ' + floorId);
    }
    return getPublicFloor(conn, tenantId, floorId).then((lastFloor) => {
      if(!lastFloor) {
        return Promise.reject('Public floor not found: ' + floorId);
      }
      var updateAt = Date.now();
      var newFloorVersion = floor.version + 1;// たぶん +1 であるという前提はおかないほうがベター

      var sqls = [];
      editingFloor.public = true;
      editingFloor.updateBy = updateBy;
      editingFloor.version = newFloorVersion;
      sqls.push(sql.insert('floors', schema.floorKeyValues(tenantId, editingFloor, updateAt)));

      floor.objects.forEach((object) => {
        object.floorVersion = newFloorVersion;
        sqls.push(sql.insert('objects', schema.objectKeyValues(object)));
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

function search(conn, tenantId, query, all, people) {
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
            objectAndFloorId : [e, e.floorId]
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
          objectAndFloorId : [e, e.floorId]
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

// function searchObjectsByName(conn, tenantId, name, all) {
//   var filterByPublic =
//     all ? '' : 'AND f.public = 1';
//
//   // TODO avoid injection
//   var sql =
//     `SELECT o.*
//        FROM map2.objects AS o, map2.floors AS f
//        WHERE o.name like "%${name}%" AND o.floorId = f.id AND o.floorVersion = f.version AND f.tenantId = "${tenantId}" ${filterByPublic}
//        ORDER BY o.id, o.floorId, o.floorVersion`;
//
//   return rdb.exec(conn, sql).then((records) => {
//     var objects = {};
//     records.forEach(record => {
//       objects[records.id] = record;// keep newest
//     });
//     return Promise.resolve(Object.keys(objects).map(objectId => {
//       return objects[objectId];
//     }));
//   });
// }

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
  saveObjectsChange: saveObjectsChange,
  // saveObject: updateObject,//TODO currently, only UPDATE is supported
  publishFloor: publishFloor,
  deleteFloor: deleteFloor,
  deleteFloorWithObjects: deleteFloorWithObjects,
  deletePrototype: deletePrototype,
  saveImage: saveImage,
  resetImage: resetImage
};
